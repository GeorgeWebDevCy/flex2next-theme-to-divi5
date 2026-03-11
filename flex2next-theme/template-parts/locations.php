<?php
/**
 * Template Part: Locations
 * Section: Thin banner listing global office locations.
 */

$locations = get_field('locations');
?>

<section class="py-12 border-y border-border bg-surface">
  <div class="max-w-7xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-8">

    <p class="text-sm font-mono text-text-subtle uppercase tracking-widest text-center md:text-left">
      Optimized for enterprise scale across global jurisdictions
    </p>

    <ul class="flex items-center gap-8 md:gap-16 opacity-60 list-none m-0 p-0" aria-label="Office locations">
      <?php if ( $locations ) : ?>
        <?php foreach ( $locations as $location ) : ?>
          <li class="flex items-center gap-2 font-bold text-xl text-foreground">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
              aria-hidden="true">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
              <path d="M2 12h20"></path>
            </svg>
            <?php echo esc_html( $location['name'] ); ?>
          </li>
        <?php endforeach; ?>
      <?php else : ?>
        <?php foreach ( [ 'London, UK', 'New York, US', 'Berlin, EU' ] as $fallback ) : ?>
          <li class="flex items-center gap-2 font-bold text-xl text-foreground">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
              aria-hidden="true">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"></path>
              <path d="M2 12h20"></path>
            </svg>
            <?php echo esc_html( $fallback ); ?>
          </li>
        <?php endforeach; ?>
      <?php endif; ?>
    </ul>

  </div>
</section>
