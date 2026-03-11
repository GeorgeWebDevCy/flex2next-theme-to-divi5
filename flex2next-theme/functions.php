<?php
/**
 * Flex2 Theme Functions
 */

// ─── Theme Support ────────────────────────────────────────────────────────────

add_theme_support('title-tag');
add_theme_support('post-thumbnails');

register_nav_menus([
  'primary' => __('Primary Menu', 'flex2'),
  'footer' => __('Footer Menu', 'flex2'),
]);


// ─── Enqueue Assets ───────────────────────────────────────────────────────────

function flex2_enqueue_assets()
{
  $uri = get_template_directory_uri();
  $version = '1.0';

  // Styles
  wp_enqueue_style('flex2-chunks-1', $uri . '/assets/chunks/25d2991e4787edd1.css', [], $version);
  wp_enqueue_style('flex2-chunks-2', $uri . '/assets/chunks/8b814ac63c348ec4.css', ['flex2-chunks-1'], $version);

  // Scripts
  wp_enqueue_script('flex2-chunk-1', $uri . '/assets/chunks/1627bf2f54f2038d.js', [], $version, true);
  wp_enqueue_script('flex2-chunk-2', $uri . '/assets/chunks/a54c4ba64f2f9a0d.js', [], $version, true);
  wp_enqueue_script('flex2-chunk-3', $uri . '/assets/chunks/f2f58a7e93290fbb.js', [], $version, true);
  wp_enqueue_script('flex2-turbopack', $uri . '/assets/chunks/turbopack-5ebadd1ad79b2be7.js', [], $version, true);
  wp_enqueue_script('flex2-chunk-4', $uri . '/assets/chunks/2f236954d6a65e12.js', [], $version, true);
  wp_enqueue_script('flex2-chunk-5', $uri . '/assets/chunks/a624b468970d3cc4.js', [], $version, true);
  wp_enqueue_script('flex2-chunk-6', $uri . '/assets/chunks/c8c74c92a17972a8.js', [], $version, true);
  wp_enqueue_script('flex2-nomodule', $uri . '/assets/chunks/a6dad97d9634a72d.js', [], $version, true);

  // Preloads (font + deferred script)
  add_action('wp_head', 'flex2_add_preloads', 1);
}
add_action('wp_enqueue_scripts', 'flex2_enqueue_assets');

function flex2_add_preloads()
{
  $uri = get_template_directory_uri();
  ?>
  <link rel="preload" href="<?php echo esc_url($uri); ?>/assets/media/797e433ab948586e-s.p.dbea232f.woff2" as="font"
    crossorigin type="font/woff2" />
  <link rel="preload" href="<?php echo esc_url($uri); ?>/assets/media/caa3a2e1cccd8315-s.p.853070df.woff2" as="font"
    crossorigin type="font/woff2" />
  <link rel="preload" href="<?php echo esc_url($uri); ?>/assets/chunks/9340e1d8acca117a.js" as="script"
    fetchpriority="low" />
  <?php
}


// ─── Icons ────────────────────────────────────────────────────────────────────

function flex2_add_icons()
{
  $uri = get_template_directory_uri();
  ?>
  <link rel="icon" href="<?php echo esc_url($uri); ?>/assets/icon-light-32x32.png"
    media="(prefers-color-scheme: light)" />
  <link rel="icon" href="<?php echo esc_url($uri); ?>/assets/icon-dark-32x32.png"
    media="(prefers-color-scheme: dark)" />
  <link rel="icon" href="<?php echo esc_url($uri); ?>/assets/icon.svg" type="image/svg+xml" />
  <link rel="apple-touch-icon" href="<?php echo esc_url($uri); ?>/assets/apple-icon.png" />
  <?php
}
add_action('wp_head', 'flex2_add_icons');


// ─── SVG Support ──────────────────────────────────────────────────────────────

// Allows admins to upload SVG files via the media library.
function flex2_allow_svg_uploads($mimes)
{
  $mimes['svg'] = 'image/svg+xml';
  return $mimes;
}
add_filter('upload_mimes', 'flex2_allow_svg_uploads');


// ─── Admin Bar ────────────────────────────────────────────────────────────────

// Prevent the admin bar from pushing the fixed nav down.
add_action('get_header', function () {
  remove_action('wp_head', '_admin_bar_bump_cb');
});


// ─── Sidebar ──────────────────────────────────────────────────────────────────

add_action('widgets_init', function () {
  register_sidebar([
    'name' => __('Sidebar', 'flex2'),
    'id' => 'sidebar-1',
  ]);
});