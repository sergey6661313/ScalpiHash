let ScalpiHash = function(output) {
    let t = this;
    
    t.mask   = 15;
    t.a      = 0;
    t.b      = 0;
    t.output = output;
    
    t.swapTwoBit = function () {
        // truncate
        const a = t.a & 7;
        const b = t.b & 7;
        
        // save bits with swap
        const tmp_a = (t.mask & (1 << a)) >> a << b;
        const tmp_b = (t.mask & (1 << b)) >> b << a;
        const tmp   = tmp_a | tmp_b;
        
        // clear bits
        t.mask &= 255 - (1 << a);
        t.mask &= 255 - (1 << b);
        
        // set last bits
        t.mask |= tmp;
    }
    t.doBit      = function (bit) {
        const bb = 2 - bit;
        t.output.forEach (function (output_byte, ind, arr) {
            t.a = (t.a + output_byte) & 255;
            t.b = (t.b + bb) & 255;
            t.swapTwoBit();
            arr[ind] = (output_byte + t.mask) & 255;
        });
    }
    t.doByte     = function (byte)  {
        let pos = 0;
        while (true) {
            const bit = (byte >> pos) & 1;
            t.doBit(bit);
            if (pos == 7) break;
            pos += 1;
        }
    }
    t.do         = function (bytes) {
        bytes.forEach(function (byte, id, arr) {
            t.doByte(byte);
        });
    }
    t.doText     = function (bytes) {
        const arr = G.lib.text.toBytes(bytes);
        this.do(arr);
    }
    t.reset      = function () {
        t.mask = 15;
        t.a = 0;
        t.b = 0;
        t.output.forEach(function (b, id, arr) {
            arr[id] = 0;
        });
    }
    t.toHex      = function () {
        let str = G.lib.bytes.toHex(t.output);
        return str;
    };
    t.print      = function () {
        let str = t.toHex();
        console.log(str);
    }
    
    return t;
};
let array      = new Uint8Array(8);
let sh         = new ScapiHash(array)
sh.doText("123");
console.log(array);