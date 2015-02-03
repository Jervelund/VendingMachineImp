// Author: Sigurd Jervelund Hansen - github.com/jervelund

// Arrays containing random messages
sales <- ["Sales are up 64% since last year!",
"With this rate, we\'re going to run out of stock soon!",
"All I do is - vend, vend, vend - no matter what!",
"Veni, Vidi, Vendi!",
"NASDAQ, here we come!",
"Say hello to my little vend!",
"I made them an offer they couldn\'t refuse.",
"Machine, Vending Machine.",
"HAL ain\'t got nothing on me!",
"A cold beverage. Shaken, not stirred.",
"Hasta la venda, Baby!",
"Madness? This is BEVERAGES!",
"To vend, or not to vend. That is the question.",
"A day without vending is like a day without sunshine.",
"Ah, excellent, another valued customer!",
"Feeling overburdened by money?",
"A fantastic day for capitalism!",
"Luke, I am your father!"];

dry <- ["Well that\'s enough to drink for today!",
"Whew, let me cool off for a minute.",
"It\'s not you - it\'s me.",
"It\'s time to kick ass and vend beverages - and I\'m all out of beverages!",
"I find my lack of beverages disturbing."];

undry <- ["Bring the big wallet, I\'m restocked!",
"Back on track, and ready to vend!"];

jam <- ["Ugh - I don\'t feel so good.",
"I\'ll be back!",
"I just can\'t do it captain - I don\'t have the power!"];

unjam <- ["I feel better already!",
"It\'s alive! It\'s alive!",
"Good as new, I think. Am I leaking?"];

// Actual tweet functions
device.on("Tweet", function(v) {
    //twitter.update_status(v);
    server.log("Tweet: "+v);
});

function randomInt(i){return math.floor(i * (1.0 * math.rand() / RAND_MAX));}

device.on("sales",function(i){twitter.update_status(sales[randomInt(sales.len())] + " (total vend count is now " + i + ")");})
device.on("dry"  ,function(i){server.log(  dry[randomInt(  dry.len())] + " (slot " + i + " is empty) @CUnnerup");})
device.on("undry",function(i){server.log(undry[randomInt(undry.len())] + " (slot " + i + " refilled)");})
device.on("jam"  ,function(i){server.log(  jam[randomInt(  jam.len())] + " (slot " + i + " jammed) @CUnnerup");})
device.on("unjam",function(i){server.log(unjam[randomInt(unjam.len())] + " (slot " + i + " is no longer jammed)");})

// Source: https://github.com/joel-wehr/Tutorial_Electric_Imp_MAX31855/blob/ef38b0fec29ec619e2c58ef2fd62e1c9776e85d3/agent.nut
//********************BEGIN TWITTER*****************
// Code by forums user bodinegl
// with a tiny bit of help from beardedinventor

function print(x) {
    server.log(x);
}

function left_rotate(x, n) { 
    // this has to handle signed integers
    return (x << n) | (x >> (32 - n)) & ~((-1 >> n) << n);
}

function swap32(val) {
    return ((val & 0xFF) << 24) | ((val & 0xFF00) << 8) | ((val >>> 8) & 0xFF00) | ((val >>> 24) & 0xFF);
}
    
function sha1(message) {

    local h0 = 0x67452301;
    local h1 = 0xEFCDAB89;
    local h2 = 0x98BADCFE;
    local h3 = 0x10325476;
    local h4 = 0xC3D2E1F0;
    local mb=blob((message.len()+9+63) & ~63)
    
    local original_byte_len = message.len();
    local original_bit_len = original_byte_len * 8;
    
    foreach (val in message) {
        mb.writen(val, 'b');
    }

    mb.writen('\x80', 'b')
    
    local l = ((56 - (original_byte_len + 1)) & 63) & 63;
    while (l--) {
          mb.writen('\x00', 'b')
  }

    mb.writen('\x00', 'i')
    mb.writen(swap32(original_bit_len), 'i')
    
    for (local i=0;i<mb.len();i+=64) {
        local w=[]; w.resize(80);

        for(local j=0;j<16;j++) {
            local s = i + j*4;
            mb.seek(s, 'b');
            w[j] = swap32(mb.readn('i'));
        }

        for(local j=16;j<80;j++) {
            w[j] = left_rotate(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);
        }
    
        local a = h0;
        local b = h1;
        local c = h2;
        local d = h3;
        local e = h4;
    
        for(local i=0;i<80;i+=1) {
            local f=0;
            local k=0;

            if (i>=0 && i<=19) {
                f = d ^ (b & (c ^ d));
                k = 0x5A827999;
            }
            else if (i>=20 && i<= 39) {
                f = b ^ c ^ d;
                k = 0x6ED9EBA1;
            }
            else if (i>=40 && i<= 59) {
                f = (b & c) | (b & d) | (c & d) ;
                k = 0x8F1BBCDC;
            }
            else if (i>=60 && i<= 79) {
                f = b ^ c ^ d;
                k = 0xCA62C1D6;
            }
            
            local _a=a
            local _b=b
            local _c=c
            local _d=d
            local _e=e
            local _f=f
            
            a = (left_rotate(_a, 5) + _f + _e + k + w[i]) & 0xffffffff;
            b = _a;
            c = left_rotate(_b, 30);
            d = _c;
            e = _d;
        }
    
        h0 = (h0 + a) & 0xffffffff
        h1 = (h1 + b) & 0xffffffff 
        h2 = (h2 + c) & 0xffffffff
        h3 = (h3 + d) & 0xffffffff
        h4 = (h4 + e) & 0xffffffff
    }
    
    local hash = blob(20);
    hash.writen(swap32(h0),'i');
    hash.writen(swap32(h1),'i');
    hash.writen(swap32(h2),'i');
    hash.writen(swap32(h3),'i');
    hash.writen(swap32(h4),'i');

    return hash;
}

function blobxor_x5c(text) {
    local len = text.len();
    local a = blob(len)
    for (local i = 0; i < len; i++) {
        a.writen(text[i] ^ 0x5c ,'b');
    }
    
    return a;
}

function blobxor_x36(text) {
    local len = text.len();
    local a = blob(len)
    for (local i = 0; i < len; i++) {
        a.writen(text[i] ^ 0x36 ,'b');
    }

    return a;
}

function blobconcat(a,b) {
    local len = b.len();
    for(local i=0; i<len; i++) {
        a.writen(b[i],'b');
    }
    return a;
}

function blobpad(s,n) {
    local b = blob(n);

    local len = s.len();    
    for(local i=0; i<len; i++) {
        b.writen(s[i],'b');
    }

    for(local i=n-s.len(); i; i--) {
       b.writen('\x00', 'b'); 
    }
    return b;
}

function hmac_sha1(key, message) {

    local _key;

    if ( key.len() > 64 ) {
        _key = blobpad(sha1(key),64);
    }
    else if ( key.len() <= 64 ) {
        _key = blobpad(key,64);
    }
    
    local _ok = blobxor_x5c(_key);
    local _ik= blobxor_x36(_key);
   
    return sha1(blobconcat(_ok, sha1(blobconcat(_ik, message))));
}

// helper function
function _printhex(s) {
    local h = "";
    for(local i=0;i<s.len();i++) h+=format("%02x", s[i]);
    return h;
}
 
// Requires hmac_sha1.nut 

class TwitterClient {
    consumerKey = null
    consumerSecret = null
    accessToken = null
    accessSecret = null
    
    baseUrl = "https://api.twitter.com/";
    
    constructor (_consumerKey, _consumerSecret, _accessToken, _accessSecret) {
        this.consumerKey = _consumerKey;
        this.consumerSecret = _consumerSecret;
        this.accessToken = _accessToken;
        this.accessSecret = _accessSecret;
    }
    
    function fmthex(s) {
        local h = ""
        for(local i=0;i<s.len();i++) h+=format("%02x", s[i]);
        return h
    }       
    
    function validChar(c) {
        if (c >= 48 && c <= 57) return true;    // numbers
        if (c >= 65 && c <= 90) return true;    // uppercase letter
        if (c >= 97 && c <= 122) return true;    // lowercase letter
        if (c == 46 || c == 45 || c == 95 || c == 126) return true;       // special characters
        
        return false;
    }
    
    function encode(str) {
        local r = "";
        foreach(s in str){
            if (validChar(s)) r += s.tochar();
            else r += "%"+format("%00x", s).toupper();
        }
        return r;
    }
    
    function sign_hmac_sha1(key, str) {
        local sign = hmac_sha1(key,str)
        server.log("sign="+fmthex(sign));
        return http.base64encode(sign)
    }
    
    function post_oauth1(postUrl, headers, post) {
        
        local time = time()
        local nonce = format("non%dce",time)


        local parm_string = http.urlencode({oauth_consumer_key=consumerKey})
        parm_string += "&"+http.urlencode({oauth_nonce=nonce})
        parm_string += "&"+http.urlencode({oauth_signature_method="HMAC-SHA1"})
        parm_string += "&"+http.urlencode({oauth_timestamp=time})
        parm_string += "&"+http.urlencode({oauth_token=accessToken})
        parm_string += "&"+http.urlencode({oauth_version="1.0"})
        parm_string += "&"+post
        
        local signature_string = "POST&"+encode(postUrl)+"&"+encode(parm_string)
        server.log("signature="+signature_string)
        
        local key = encode(consumerSecret)+"&"+encode(accessSecret)
        local sha1 = encode(sign_hmac_sha1(key, signature_string))
        server.log("key="+key+", sha1="+sha1)

        local auth_header = "oauth_consumer_key=\""+consumerKey+"\","
        auth_header += "oauth_nonce=\""+nonce+"\","
        auth_header += "oauth_signature=\""+sha1+"\","
        auth_header += "oauth_signature_method=\""+"HMAC-SHA1"+"\","
        auth_header += "oauth_timestamp=\""+time+"\","
        auth_header += "oauth_token=\""+accessToken+"\","
        auth_header += "oauth_version=\"1.0\""
        server.log(auth_header)
        
        local headers = { 
            "Authorization": "OAuth "+auth_header,
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
        };
        
        local response = http.post(postUrl, headers, post).sendsync();
        
        server.log("response="+response);
        return response
    }
    
    function update_status(status) {
        local postUrl = baseUrl + "1.1/statuses/update.json";
    
        local headers = { };
        local post = "status="+encode(status);
        
        local response = post_oauth1(postUrl, headers, post)
        if (response && response.statuscode != 200) {
            server.log("Error updating_status tweet. HTTP Status Code " + response.statuscode);
            server.log(response.body);
            return null;
        }
    }

}

// Get your keys here: https://apps.twitter.com/app/
_CONSUMER_KEY <- "xxx"
_CONSUMER_SECRET <- "xxx"
_ACCESS_TOKEN <- "xxx"
_ACCESS_SECRET <- "xxx"

twitter <- TwitterClient(_CONSUMER_KEY, _CONSUMER_SECRET, _ACCESS_TOKEN, _ACCESS_SECRET);
//**************************END TWITTER*****************************************
