const os = require('os');
const { spawnSync } = require('child_process');
const platform = os.platform();
const moduleName = 'Milky2018/moon_rodio';

if (platform !== 'darwin' && platform !== 'linux' && platform !== 'win32') {
  throw new Error(`Unsupported platform: ${platform}`);
}

function pkg(path) {
  return path.length === 0 ? moduleName : `${moduleName}/${path}`;
}

const linkConfigs = [];

function addLinkConfig(path, config) {
  linkConfigs.push({
    package: pkg(path),
    ...config,
  });
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
let decoderLinkFlags = '';

const envFfmpegCflags = process.env.MOON_RODIO_FFMPEG_CFLAGS || '';
const envFfmpegLibs = process.env.MOON_RODIO_FFMPEG_LIBS || '';
if (platform === 'darwin') {
  decoderLinkFlags =
    '-framework CoreAudio -framework CoreFoundation -framework AudioToolbox';
} else if (envFfmpegCflags !== '' && envFfmpegLibs !== '') {
  decoderStubCcFlags = `${envFfmpegCflags} -DMOON_RODIO_ENABLE_FFMPEG=1`;
  decoderLinkFlags = envFfmpegLibs;
} else if (platform === 'linux') {
  const ffmpeg = probePkgConfig([
    'libavformat',
    'libavcodec',
    'libavutil',
    'libswresample',
  ]);
  if (ffmpeg) {
    decoderStubCcFlags = `${ffmpeg.cflags} -DMOON_RODIO_ENABLE_FFMPEG=1`;
    decoderLinkFlags = ffmpeg.libs;
  }
}

if (decoderLinkFlags !== '') {
  addLinkConfig('decoder', { link_flags: decoderLinkFlags });
}

const output = {
  vars: {
    MOON_RODIO_DECODER_STUB_CC_FLAGS: decoderStubCcFlags,
  },
  link_configs: linkConfigs,
};

console.log(JSON.stringify(output));
