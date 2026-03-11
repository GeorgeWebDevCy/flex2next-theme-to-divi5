<?php
/**
 * Template Part: Hero
 * Section: Full-screen hero with badge, headline, description, and CTA.
 */

$badge       = get_field('hero_badge') ?: 'The New Standard in B2B AI';
$title       = get_field('hero_title') ?: 'Invisible<br /><span class="text-transparent bg-clip-text bg-gradient-to-b from-foreground to-foreground/30">Intelligence.</span>';
$description = get_field('hero_description') ?: 'We engineer bespoke automation workflows that silently eradicate tedious admin, drastically reduce overhead, and scale your business globally.';
$coverage    = get_field('market_coverage') ?: 'Servicing UK, US & EU Markets';
?>

<section class="relative pt-40 pb-32 px-6 min-h-screen flex flex-col justify-center items-center text-center">

  

  <h1 class="text-6xl md:text-8xl lg:text-[10rem] font-bold tracking-tighter leading-[0.9] mb-8 text-foreground">
    <?php echo $title; ?>
  </h1>

  <p class="text-xl md:text-3xl text-text-secondary max-w-3xl mx-auto leading-relaxed font-light mb-12">
    <?php echo $description; ?>
  </p>

  <div class="flex flex-col sm:flex-row items-center gap-4">
    <a href="#contact"
      class="px-8 py-4 bg-primary text-primary-foreground text-lg font-bold rounded-full hover:bg-primary/90 transition-all flex items-center gap-2 btn-glow w-full sm:w-auto justify-center">
      Automate Your Future
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
        aria-hidden="true">
        <path d="M5 12h14"></path>
        <path d="m12 5 7 7-7 7"></path>
      </svg>
    </a>
    <p class="text-xs font-mono text-text-tertiary uppercase tracking-widest mt-4 sm:mt-0 sm:ml-4">
      <?php echo $coverage; ?>
    </p>
  </div>

</section>
