<?php
/**
 * Template Part: Philosophy
 * Section: Two-column layout with title, subtitle, body content, and decorative graphic.
 */
?>

<section id="philosophy" class="py-32 px-6">
  <div class="max-w-7xl mx-auto">

    <h2 class="text-4xl md:text-6xl font-bold tracking-tighter mb-16 max-w-4xl leading-tight text-foreground text-balance">
      <?php the_field('philosophy_title'); ?>
    </h2>

    <div class="grid md:grid-cols-2 gap-16 md:gap-32">

      <div class="flex flex-col gap-6">
        <h3 class="text-2xl font-semibold text-foreground">
          <?php the_field('philosophy_subtitle'); ?>
        </h3>
        <div class="text-lg text-text-secondary leading-relaxed font-light">
          <?php the_field('philosophy_content'); ?>
        </div>
      </div>

      <div class="relative aspect-square rounded-3xl border border-border bg-gradient-to-br from-surface to-transparent flex items-center justify-center overflow-hidden"
        aria-hidden="true">
        <div class="absolute inset-0 dot-pattern"></div>
        <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"
          class="text-foreground/20">
          <rect x="16" y="16" width="6" height="6" rx="1"></rect>
          <rect x="2" y="16" width="6" height="6" rx="1"></rect>
          <rect x="9" y="2" width="6" height="6" rx="1"></rect>
          <path d="M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3"></path>
          <path d="M12 12V8"></path>
        </svg>
      </div>

    </div>
  </div>
</section>
