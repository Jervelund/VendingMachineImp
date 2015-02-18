// Author: Sigurd Jervelund Hansen - github.com/jervelund

local uart_str = "";
local ArrayD = [0,0,0,0,0,0,0];
local ArrayJ = [0,0,0,0,0,0,0];
local lastSalesCount = 0;

function buildArray(str){
  local newArray = [0,0,0,0,0,0,0];
  local index = 0;
  for(local i=0;str.len()>i;i++){
    index = str[i].tointeger()-'0';
    newArray[index] = 1;
  }
  return newArray;
}

function parseData(str){
  local substr = str.slice(1);
  switch(str[0]){
    case 'B': // Bought beverages in total
      local newSalesCount = substr.tointeger();
      if(lastSalesCount > 0 && lastSalesCount != newSalesCount){
        agent.send("sales",newSalesCount);
      }
      lastSalesCount = newSalesCount;
    break;
    case 'J': // Jammed slot
      local newArray = buildArray(substr);
      local change = 0;
      // Check for changes
      for(local i=0;newArray.len()>i;i++){
        change = newArray[i]-ArrayJ[i];
        if(change == 1){
          agent.send("jam",i);
        }
        if(change == -1){
          agent.send("unjam",i);
        }
      }
      ArrayJ = newArray;
    break;
    case 'D': // Dry slot
      local newArray = buildArray(substr);
      local change = 0;
      // Check for changes
      for(local i=0;newArray.len()>i;i++){
        change = newArray[i]-ArrayD[i];
        if(change == 1){
          agent.send("dry",i);
        }
        if(change == -1){
          agent.send("undry",i);
        }
      }
      ArrayD = newArray;
    break;
    case 'R': // coin Return tray empty
      // Todo
    break;
    default:
      server.log("UNKNOWN STR: "+str);
    break;
  }
}

function uartData(){
  local b = arduino.read();
  while(b != -1){
    if(b == ','){
      server.log(uart_str);
      parseData(uart_str);
      uart_str = "";
    } else {
      if(b != 'c')
        uart_str += b.tochar();
    }
    b = arduino.read();
  }
}

arduino <- hardware.uart57;
arduino.configure(57600, 8, PARITY_NONE, 1, NO_CTSRTS, uartData);
