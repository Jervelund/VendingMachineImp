// Author: Sigurd Jervelund Hansen - github.com/jervelund

local uart_str = "";
local ArrayD = [0,0,0,0,0,0,0];
local ArrayJ = [0,0,0,0,0,0,0];
local ArrayR = [0,0,0,0,0,0,0];
local lastSalesCount = 0;

function parseData(str){
  local substr = str.slice(1);
  switch(str[0]){
    case 'B': // Bought beverages in total
      local newSalesCount = substr.tointeger();
      if(lastSalesCount > 0 && lastSalesCount != newSalesCount){
        agent.send("sales",lastSalesCount);
      }
      lastSalesCount = newSalesCount;
    break;
    case 'J': // Jammed slot
      //server.log("J: "+str);
    break;
    case 'D': // Dry slot
      //server.log("D: "+str);
    break;
    case 'R': // Return tray empty
      //server.log("R: "+str);
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

//agent.send("Tweet","Dammit, RaspberryPI. Stop frying your SD cards!");
//agent.send("sales","2000");

//agent.send("jam","2");
//agent.send("unjam","2");

//agent.send("dry","2");
//agent.send("undry","2");