"use strict";

import gulp from "gulp";
import concat from "gulp-concat";
import include from "gulp-include";
import plumber from "gulp-plumber";
import uglify from "gulp-uglify";
import yaml from "gulp-yaml";
import browserSync from "browser-sync";
import cp from "child_process";
import fs from "fs";


/**
 * Notify
 * 
 * Show a notification in the browser's corner.
 * 
 * @param {*} message 
 */
function notify(message) {
  browserSync.notify(message);
}

/**
 * Config Task
 * 
 * Build the main YAML config file.
 */
function config() {
  return gulp.src('src/yml/_config.yml')
    .pipe(include())
    .on('error', console.error)
    .pipe(gulp.dest('./'));
}

/**
 * Jekyll Task
 * 
 * Build the Jekyll Site.
 * 
 * @param {*} done 
 */
function jekyll(done) {
  notify('Building Jekyll...');
  const rubyGlobCompat = [
    'class << Dir',
    'alias_method :jekyll_original_glob, :[] unless method_defined?(:jekyll_original_glob)',
    'def [](*patterns)',
    'results = jekyll_original_glob(*patterns)',
    'return results unless results.empty? && patterns.length == 1',
    'pattern = patterns.first',
    'return results unless pattern.match?(/[?*\\[\\{]/)',
    'dir = File.dirname(pattern)',
    'return results unless File.directory?(dir)',
    'names = [File.basename(pattern)]',
    'names = names.flat_map { |name| name.include?("{_,}") ? [name.sub("{_,}", "_"), name.sub("{_,}", "")] : [name] }',
    'Dir.children(dir).select { |entry| names.any? { |name| File.fnmatch?(name, entry) } }.map { |entry| File.join(dir, entry) }.sort',
    'end',
    'end',
    'load Gem.bin_path("jekyll", "jekyll")',
  ].join('; ');
  const hasMiseRuby = process.platform !== "win32"
    && cp.spawnSync('mise', ['current', 'ruby'], { stdio: 'ignore' }).status === 0;
  const command = process.platform === "win32" ? "cmd" : hasMiseRuby ? "mise" : "bundle";
  const args = process.platform === "win32"
    ? ['/c', 'bundle', 'exec', 'ruby', '-e', rubyGlobCompat, 'build']
    : hasMiseRuby
      ? ['exec', 'ruby', '--', 'bundle', 'exec', 'ruby', '-e', rubyGlobCompat, 'build']
      : ['exec', 'ruby', '-e', rubyGlobCompat, 'build'];
  const child = cp.spawn(command, args, { stdio: 'inherit' });
  child.on('error', done);
  child.on('close', (code) => {
    if (code === 0) {
      done();
      return;
    }
    done(new Error(`Jekyll build failed with exit code ${code}`));
  });
  return child;
}

/**
 * Server Task
 * 
 * Launch server using BrowserSync.
 * 
 * @param {*} done 
 */
function server(done) {
  browserSync({
    server: {
      baseDir: '_site'
    }
  });
  done();
}

/**
 * Reload Task
 * 
 * Reload page with BrowserSync.
 * 
 * @param {*} done 
 */
function reload(done) {
  notify('Reloading...');
  browserSync.reload();
  done();
}

/**
 * Theme Tasks
 * 
 * These three tasks are responsible for:
 * 1. Converting src/yml/theme.yml to src/tmp/theme.json
 * 2. Converting src/tmp/theme.json to _sass/_theme.scss
 * 3. Deleting src/tmp
 * 
 * With these tasks we can apply the theme colors to SVGs and CSS elements using
 * just the src/yml/theme.yml file.
 */

function yamlTheme() {
  return gulp.src('src/yml/theme.yml')
    .pipe(yaml({ schema: 'DEFAULT_SAFE_SCHEMA' }))
    .pipe(gulp.dest('src/tmp/'));
}

async function jsonTheme() {
  const themeJson = await fs.promises.readFile('src/tmp/theme.json', 'utf8');
  const theme = JSON.parse(themeJson);
  const entries = Object.entries(theme)
    .map(([name, value]) => `  ${name}: ${value}`)
    .join(',\n');

  await fs.promises.writeFile('_sass/_theme.scss', `$theme: (\n${entries}\n);`, 'utf8');
}

async function cleanTheme() {
  await fs.promises.rm('src/tmp', { recursive: true, force: true });
}

const theme = gulp.series(yamlTheme, jsonTheme, cleanTheme);

/**
 * Main JS Task
 * 
 * All regular .js files are collected, minified and concatonated into one
 * single scripts.min.js file (and sourcemap)
 */
function mainJs() {
  notify('Building JS files...');
  return gulp.src('src/js/main/**/*.js')
    .pipe(plumber())
    .pipe(uglify())
    .pipe(concat('scripts.min.js'))
    .pipe(gulp.dest('_site/assets/js/'))
    .pipe(browserSync.reload({ stream: true }))
    .pipe(gulp.dest('assets/js'));
}

/**
 * Preview JS Task
 * 
 * Copy preview JS files to the assets folder.
 */
function previewJs() {
  notify('Copying preview files...');
  return gulp.src('src/js/preview/**/*.*')
    .pipe(gulp.dest('assets/js/'));
}

/**
 * JavaScript Task
 * 
 * Run all the JS related tasks.
 */
const js = gulp.parallel(mainJs, previewJs);

/**
 * Watch Task
 * 
 * Watch files to run proper tasks.
 */
function watch() {
  // Watch YAML files for changes & recompile
  gulp.watch(['src/yml/*.yml', '!src/yml/theme.yml'], gulp.series(config, jekyll, reload));

  // Watch theme file for changes, rebuild styles & recompile
  gulp.watch(['src/yml/theme.yml'], gulp.series(theme, config, jekyll, reload));

  // Watch SASS files for changes & rebuild styles
  gulp.watch(['_sass/**/*.scss'], gulp.series(jekyll, reload));

  // Watch JS files for changes & recompile
  gulp.watch('src/js/main/**/*.js', mainJs);

  // Watch preview JS files for changes, copy files & reload
  gulp.watch('src/js/preview/**/*.js', gulp.series(previewJs, reload));

  // Watch html/md files, rebuild config, run Jekyll & reload BrowserSync
  gulp.watch(['*.html', '_includes/*.html', '_layouts/*.html', '_posts/*', 'pages/*'], gulp.series(config, jekyll, reload));
}

/**
 * Default Task
 *
 * Running just `gulp` will:
 * - Compile the theme, SASS and JavaScript files
 * - Build the config file
 * - Compile the Jekyll site
 * - Launch BrowserSync & watch files
 */
const run = gulp.series(gulp.parallel(js, theme), config, jekyll, gulp.parallel(server, watch));

/**
 * Build Task
 * 
 * Running just `gulp build` will:
 * - Compile the theme, SASS and JavaScript files
 * - Build the config file
 * - Compile the Jekyll site
 */
const build = gulp.series(gulp.parallel(js, theme), config, jekyll);

export { run as default, build };
