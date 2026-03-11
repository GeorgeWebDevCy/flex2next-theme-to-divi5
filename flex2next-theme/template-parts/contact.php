<?php
/**
 * Template Part: Contact
 * Section: CTA with contact form rendered via shortcode from ACF field.
 */

$heading     = get_field('contact_heading') ?: 'Initiate Evolution.';
$subtext     = get_field('contact_subtext') ?: 'Secure your consultation. Discover exactly how much time and capital Flex2 Ai can reclaim for your enterprise.';
$form_sc     = get_field('contact_form_shortcode');
?>

<section id="contact" class="py-32 px-6 relative overflow-hidden">

  <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-surface rounded-full blur-[120px] -z-10 pointer-events-none"
    aria-hidden="true"></div>

  <div class="max-w-3xl mx-auto">

    <div class="text-center mb-16">
      <h2 class="text-5xl md:text-7xl font-bold tracking-tighter mb-6 text-foreground">
        <?php echo esc_html( $heading ); ?>
      </h2>
      <p class="text-xl text-text-secondary font-light">
        <?php echo esc_html( $subtext ); ?>
      </p>
    </div>

    <div class="bg-surface p-8 md:p-12 rounded-3xl border border-border backdrop-blur-sm">
      <?php
      if ( $form_sc ) {
        echo do_shortcode( $form_sc );
      } else {
        if ( WP_DEBUG ) {
          echo '<!-- Contact form shortcode not set in ACF field: contact_form_shortcode -->';
        }
      }
      ?>
    </div>

  </div>

</section>
