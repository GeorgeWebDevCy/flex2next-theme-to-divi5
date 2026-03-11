<!DOCTYPE html>
<html <?php language_attributes(); ?>
  class="geist_dd5f33c6-module__WggDGG__variable geist_mono_d6617093-module__z61v7q__variable">

<head>
  <meta charset="<?php bloginfo('charset'); ?>" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <?php wp_head(); ?>
</head>

<body <?php body_class('font-sans antialiased'); ?>>

  <div class="min-h-screen font-sans selection:bg-foreground selection:text-background">

    <div
      class="fixed inset-0 -z-10 bg-[radial-gradient(circle_at_50%_50%,_oklch(0.12_0_0)_0%,_oklch(0_0_0)_100%)] overflow-hidden"
      aria-hidden="true">
      <div class="ambient-orb w-[40vw] h-[40vw] bg-foreground/5 -top-[10%] -left-[10%] absolute"></div>
      <div class="ambient-orb w-[30vw] h-[30vw] bg-foreground/[0.03] -bottom-[10%] -right-[10%] absolute"
        style="animation-delay: -5s"></div>
    </div>

    <nav class="fixed top-0 w-full z-50 border-b border-border bg-background/50 backdrop-blur-md">
      <div class="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">

        <a href="<?php echo esc_url(home_url('/')); ?>" class="flex items-center gap-2"
          aria-label="<?php bloginfo('name'); ?> Home">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
            class="w-6 h-6 text-foreground" aria-hidden="true">
            <path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"></path>
          </svg>
          <span class="text-xl font-bold tracking-tighter text-foreground"><?php bloginfo('name'); ?></span>
        </a>

        <div class="hidden md:flex items-center gap-8 text-sm font-medium text-text-subtle">
          <a href="#philosophy" class="hover:text-foreground transition-colors">Philosophy</a>
          <a href="#workflows" class="hover:text-foreground transition-colors">Workflows</a>
          <a href="#benefits" class="hover:text-foreground transition-colors">Benefits</a>
        </div>

        <a href="#contact"
          class="px-5 py-2.5 bg-primary text-primary-foreground text-sm font-bold rounded-full hover:bg-primary/90 transition-all btn-glow">
          Initiate Consultation
        </a>

      </div>
    </nav>