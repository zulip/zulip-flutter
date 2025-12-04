/**
 * Rebuild our custom icon font ZulipIcons.ttf, and the ZulipIcons class.
 *
 * This script is typically run via the wrapper `build-icon-font`.
 *
 * To use these icons, use the ZulipIcons class in the same way
 * as one uses the Flutter Material library's Icons class.
 *
 * To add a new icon, see comments on the ZulipIcons class.
 */

// This is a NodeJS script, rather than Dart, in order to use
// the same convenient web of third-party tools ("@vusion/webfonts-generator"
// and its dependencies) as we use in Zulip web and zulip-mobile:
//   https://chat.zulip.org/#narrow/stream/243-mobile-team/topic/custom.20icons/near/1338108

const fs = require('fs');
const os = require('os');
const path = require('path');
const webfontsGenerator = require('@vusion/webfonts-generator');

// The root of our tree.
const rootDir = path.dirname(path.dirname(__dirname));

const fontName = 'Zulip Icons';
const fontFileBaseName = fontName.replaceAll(' ', '');

const srcDir = path.join(rootDir, 'assets', 'icons');
const destDir = srcDir;
const dataOutputFile = path.join(rootDir, 'lib', 'widgets', 'icons.dart');
const dataTemplateFile = dataOutputFile;

async function main() {
  const iconFiles = fs
    .readdirSync(srcDir)
    .filter(name => name.endsWith('.svg'))
    .map(name => path.join(srcDir, name))
    .sort(); // prevent inconsistent results across platforms

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'build-icon-font-'));

  // This gets mutated by `webfonts-generator` to tell us the generated mapping.
  const codepoints = {};

  await new Promise((resolve, reject) =>
    webfontsGenerator(
      {
        dest: tmpDir,
        codepoints,
        fontName,
        files: iconFiles,

        types: ['ttf'],
        css: false,
        // Useful for debugging:
        //   html: true,
      },
      err => (err ? reject(err) : resolve()),
    ),
  );

  fs.copyFileSync(path.join(tmpDir, `${fontName}.ttf`), path.join(destDir, `${fontFileBaseName}.ttf`));

  const template = fs.readFileSync(dataTemplateFile, 'utf8');

  // Icons that should flip horizontally in RTL layout.
  const directionalIconsFile = path.join(srcDir, 'directional_icons.js');
  const directionalIcons = require(directionalIconsFile);

  const generated = Object.entries(codepoints).map(([name, codepoint]) => {
    const codepointHex = "0x" + codepoint.toString(16);

    const namedParams = [`fontFamily: "${fontName}"`];
    if (directionalIcons.includes(name)) {
      namedParams.push('matchTextDirection: true');
    }

    return `\

  /// The Zulip custom icon "${name}".
  static const IconData ${name} = IconData(${codepointHex}, ${namedParams.join(', ')});
`;
  }).join("");
  const output = template.replace(
    RegExp('(?<=^\\s*// BEGIN GENERATED ICON DATA\\s*\\n)'
         + '.*?'
         + '(?=^\\s*// END GENERATED ICON DATA\\s*$)',
           "ms"),
    generated);
  fs.writeFileSync(dataOutputFile, output);
  fs.rmSync(tmpDir, { recursive: true });
}

main();
