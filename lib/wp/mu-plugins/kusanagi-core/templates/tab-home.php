<?php
if ( ! defined( 'ABSPATH' ) ) exit;

$this->form_submit = false;
$rss = fetch_feed( __( 'http://en.kusanagi.tokyo/feed/', 'wp-kusanagi' ) );
$maxitems = 0;
if ( ! is_wp_error( $rss ) ) {
	$maxitems = $rss->get_item_quantity( 5 ); 
	$rss_items = $rss->get_items( 0, $maxitems );
}
?>
<h3><?php _e( 'Modules', 'wp-kusanagi' ); ?></h3>
<ul class="kusanagi-module-desc">
	<li>
		<h4><?php _e( 'Page Cache', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="textinner">
				<?php _e( '<p>Page cache is a function for saving an HTML to display as a temporary data and reusing it in order to improve the WordPress performance.</p>', 'wp-kusanagi' ); ?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php _e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'page-cache' ), $this->home_url ) ); ?>"><?php _e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
	<li>
		<h4><?php _e( 'Device Theme Switcher', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="textinner">
				<?php _e( '<p>Device switching is a function to change and optimize a theme to display for mobile terminals such as a smartphone.</p>', 'wp-kusanagi' ); ?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php _e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'theme-switcher' ), $this->home_url ) ); ?>"><?php _e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
	<li>
		<h4><?php _e( 'Translate Accelerator', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="inner">
				<?php _e( '<p>Translate Accelerator makes the translation cache files, and shortens the execution time to display your WordPress site.</p>', 'wp-kusanagi' ); ?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php _e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'translate-accelerator' ), $this->home_url ) ); ?>"><?php _e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
</ul>
<?php if ( $maxitems ) : ?>
<h3><?php _e( 'Information', 'wp-kusanagi' ); ?></h3>
<ul class="kusanagi-informations">
	<?php $cnt = 1; foreach ( $rss_items as $rss_item ) : ?>
		<li<?php echo $cnt == $maxitems ? ' class="tail"' : ''; ?>>
			<span class="pub-date"><?php echo esc_html( $rss_item->get_date( get_option( 'date_format' ) ) ); ?></span>
			<a href="<?php echo esc_url( $rss_item->get_permalink() ); ?>">
				<?php echo esc_html( $rss_item->get_title() ); ?>
			</a>
		</li>
	<?php $cnt++; endforeach; ?>
</ul>
<?php endif; ?>
