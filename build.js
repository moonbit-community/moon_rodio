const os = require('os');
const platform = os.platform();

let ccLinkFlags = '';
if (platform === 'darwin') {
  ccLinkFlags =
    '-framework CoreAudio -framework CoreFoundation -framework AudioToolbox';
} else if (platform === 'linux') {
  ccLinkFlags = '-pthread -lasound -ljack';
} else if (platform === 'win32') {
  ccLinkFlags = '-lole32 -luuid -lmmdevapi -lavrt';
} else {
  throw new Error(`Unsupported platform: ${platform}`);
}

const output = {
  vars: {
    MOON_RODIO_CC_LINK_FLAGS: ccLinkFlags,
  },
};

console.log(JSON.stringify(output));
