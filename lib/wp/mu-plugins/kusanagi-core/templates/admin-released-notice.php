<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$response = wp_remote_get( 'https://api.prime-strategy.co.jp/kusanagi/plugins.php?name=wp-kusanagi&type=plugin' );
if ( is_wp_error( $response ) ) {
	return;
}
$latest_plugin  = json_decode( wp_remote_retrieve_body( $response ), true );
$latest_version = '0.0.0';
if ( isset( $latest_plugin['new_version'] ) ) {
	$latest_version = $latest_plugin['new_version'];
}
if ( version_compare( $this->version, $latest_version, '<' ) ) :
	?>
	<div class="notice notice-warning">
		<p>
			<?php
				/* translators: 1: Latest version. */
				echo esc_html( sprintf( __( 'A new version of the KUSANAGI plugin, "%s", has been released.', 'wp-kusanagi' ), esc_attr( $latest_version ) ) );
			?>
			<br>
			<br>
			<?php esc_html_e( 'The module update can be applied with the following command:', 'wp-kusanagi' ); ?><br>
			<code><?php esc_html_e( '# dnf upgrade kusanagi kusanagi-wp-plugins', 'wp-kusanagi' ); ?></code><br>
			<br>
			<?php esc_html_e( 'After module update, please update KUSANAGI plugin of the profile with the following command:', 'wp-kusanagi' ); ?><br>
			<code><?php esc_html_e( '# kusanagi update plugin profile', 'wp-kusanagi' ); ?></code>
		</p>
	</div>
<?php endif; ?>
