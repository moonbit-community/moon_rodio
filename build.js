const os = require('os');
const { spawnSync } = require('child_process');
const platform = os.platform();

let ccLinkFlags = '';
if (platform === 'darwin') {
  ccLinkFlags =
    '-framework CoreAudio -framework CoreFoundation -framework AudioToolbox';
} else if (platform === 'linux') {
  ccLinkFlags = '-pthread -lasound -ljack';
} else if (platform === 'win32') {
  ccLinkFlags = 'ole32.lib uuid.lib mmdevapi.lib avrt.lib';
} else {
  throw new Error(`Unsupported platform: ${platform}`);
}

function probePkgConfig(packages) {
  const cflags = spawnSync('pkg-config', ['--cflags', ...packages], {
    encoding: 'utf8',
  });
  const libs = spawnSync('pkg-config', ['--libs', ...packages], {
    encoding: 'utf8',
  });
  if (cflags.status !== 0 || libs.status !== 0) {
    return null;
  }
  return {
    cflags: cflags.stdout.trim(),
    libs: libs.stdout.trim(),
  };
}

let decoderStubCcFlags = '';
let decoderCcLinkFlags = '';

const envFfmpegCflags = process.env.MOON_RODIO_FFMPEG_CFLAGS || '';
const envFfmpegLibs = process.env.MOON_RODIO_FFMPEG_LIBS || '';
if (envFfmpegCflags !== '' && envFfmpegLibs !== '') {
  decoderStubCcFlags = `${envFfmpegCflags} -DMOON_RODIO_ENABLE_FFMPEG=1`;
  decoderCcLinkFlags = envFfmpegLibs;
} else if (platform === 'linux') {
  const ffmpeg = probePkgConfig([
    'libavformat',
    'libavcodec',
    'libavutil',
    'libswresample',
  ]);
  if (ffmpeg) {
    decoderStubCcFlags = `${ffmpeg.cflags} -DMOON_RODIO_ENABLE_FFMPEG=1`;
    decoderCcLinkFlags = ffmpeg.libs;
  }
}

const output = {
  vars: {
    MOON_RODIO_CC_LINK_FLAGS: ccLinkFlags,
    MOON_RODIO_DECODER_STUB_CC_FLAGS: decoderStubCcFlags,
    MOON_RODIO_DECODER_CC_LINK_FLAGS: decoderCcLinkFlags,
  },
};

console.log(JSON.stringify(output));
