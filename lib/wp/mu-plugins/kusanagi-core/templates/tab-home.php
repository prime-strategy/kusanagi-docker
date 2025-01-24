<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$this->form_submit = false;
$current_locale    = get_locale();
if ( function_exists( 'determine_locale' ) ) {
	$current_locale = determine_locale();
}
function kusanagi_rss_items( $url ) {
	$rss = fetch_feed( $url );

	$max_items = 0;
	if ( ! is_wp_error( $rss ) ) {
		$max_items = $rss->get_item_quantity( 5 );
		$rss_items = $rss->get_items( 0, $max_items );
	}

	if ( $max_items ) {
		$html = '<ul class="kusanagi-informations">';
		foreach ( $rss_items as $index => $rss_item ) {
			$html .= '<li class="' . ( $index + 1 === $max_items ? 'tail' : '' ) . '">';
			$html .= '<span class="pub-date">' . esc_html( $rss_item->get_date( get_option( 'date_format' ) ) ) . '</span>';
			$html .= '<a href="' . esc_url( $rss_item->get_permalink() ) . '">';
			$html .= esc_html( $rss_item->get_title() );
			$html .= '</a>';
			$html .= '</li>';
		}
		$html .= '</ul>';
		// phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
		echo $html;
	}
}
?>
<h3><?php esc_html_e( 'Modules', 'wp-kusanagi' ); ?></h3>
<ul class="kusanagi-module-desc">
<?php if ( ! is_plugin_active( 'wp-sitemanager/wp-sitemanager.php' ) ) : ?>
	<li>
		<h4><?php esc_html_e( 'Page Cache', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="textinner">
				<?php
				// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
				_e( '<p>Page cache is a function for saving an HTML to display as a temporary data and reusing it in order to improve the WordPress performance.</p>', 'wp-kusanagi' );
				?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php esc_html_e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'page-cache' ), $this->home_url ) ); ?>"><?php esc_html_e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
<?php endif; ?>
	<li>
		<h4><?php esc_html_e( 'Device Theme Switcher', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="textinner">
				<?php
				// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
				_e( '<p>Device switching is a function to change and optimize a theme to display for mobile terminals such as a smartphone.</p>', 'wp-kusanagi' );
				?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php esc_html_e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'theme-switcher' ), $this->home_url ) ); ?>"><?php esc_html_e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
	<li>
		<h4><?php esc_html_e( 'Translate Accelerator', 'wp-kusanagi' ); ?></h4>
		<div class="desc">
			<div class="inner">
				<?php
				// phpcs:ignore WordPress.Security.EscapeOutput.UnsafePrintingFunction
				_e( '<p>Translate Accelerator makes the translation cache files, and shortens the execution time to display your WordPress site.</p>', 'wp-kusanagi' );
				?>
			</div>
		</div>
		<div class="link">
			<?php /* <a class="to-help-page button" href=""><?php esc_html_e( 'Help', 'wp-kusanagi' ); ?></a> */ ?>
			<a class="to-settings-page button" href="<?php echo esc_url( add_query_arg( array( 'tab' => 'translate-accelerator' ), $this->home_url ) ); ?>"><?php esc_html_e( 'Settings', 'wp-kusanagi' ); ?></a>
		</div>
	</li>
</ul>

<h3><?php esc_html_e( 'Information', 'wp-kusanagi' ); ?></h3>
<?php kusanagi_rss_items( __( 'https://kusanagi.tokyo/en/feed/', 'wp-kusanagi' ) ); ?>
<?php if ( 'ja' === $current_locale ) : ?>
	<h3><?php esc_html_e( 'KUSANAGI Tech Column', 'wp-kusanagi' ); ?></h3>
	<?php kusanagi_rss_items( __( 'https://www.prime-strategy.co.jp/column/feed/', 'wp-kusanagi' ) ); ?>
	<h3><?php esc_html_e( 'Events and Seminars', 'wp-kusanagi' ); ?></h3>
	<?php kusanagi_rss_items( __( 'https://www.prime-strategy.co.jp/information-category/event_and_seminars/feed/', 'wp-kusanagi' ) ); ?>
<?php endif; ?>
