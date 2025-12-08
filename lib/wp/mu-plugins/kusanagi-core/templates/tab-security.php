<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// phpcs:disable WordPress.WP.I18n.NonSingularStringLiteralText
$current_module    = $this->modules[ sanitize_text_field( $_GET['tab'] ) ];
$settings          = $current_module->settings;
$ms_settings       = $current_module->ms_settings;
if ( is_multisite() ) {
	if ( is_network_admin() ) {
		$disable_xmlrpc    = $ms_settings['disable_xmlrpc'];
		$disable_api_users = $ms_settings['disable_api_users'];
	} else {
		$disable_xmlrpc    = $settings['disable_xmlrpc'];
		$disable_api_users = $settings['disable_api_users'];
	}
} else {
	$disable_xmlrpc    = $settings['disable_xmlrpc'];
	$disable_api_users = $settings['disable_api_users'];
}
?>
	<h3><?php esc_html_e( 'Security', 'wp-kusanagi' ); ?></h3>
	<table class="form-table">
		<tr>
			<th><?php esc_html_e( 'XML-RPC', 'wp-kusanagi' ); ?></th>
			<td>
<?php if ( is_multisite() && ! is_network_admin() && $ms_settings['disable_xmlrpc'] ) : ?>
				<p><?php esc_html_e( 'XML-RPC is disabled by KUSANAGI configuration of Network Admin', 'wp-kusanagi' ); ?></p>
<?php else : ?>
				<input type="hidden" name="disable_xmlrpc" value="0">
				<label for="disable-xmlrpc">
				<input type="checkbox" id="disable-xmlrpc" name="disable_xmlrpc" value="1"<?php echo '1' === $disable_xmlrpc ? ' checked="checked"' : ''; ?>>
					<?php echo esc_html_e( 'Disable', 'wp-kusanagi' ); ?>
				</label>
<?php endif; ?>
			</td>
		</tr>
		<tr>
			<th><?php esc_html_e( 'WordPress REST API endpoint for requesting user resources', 'wp-kusanagi' ); ?></th>
			<td>
<?php if ( is_multisite() && ! is_network_admin() && $ms_settings['disable_api_users'] ) : ?>
				<p><?php esc_html_e( 'WordPress REST API endpoint for requesting user resources is disabled by KUSANAGI configuration of Network Admin', 'wp-kusanagi' ); ?></p>
<?php else : ?>
				<input type="hidden" name="disable_api_users" value="0">
				<label for="disable-api-users">
					<input type="checkbox" id="disable-api-users" name="disable_api_users" value="1"<?php echo '1' === $disable_api_users ? ' checked="checked"' : ''; ?>>
					<?php echo esc_html_e( 'Disable', 'wp-kusanagi' ); ?>
				</label>
<?php endif; ?>
			</td>
		</tr>
	</table>
<?php if ( is_multisite() && is_network_admin() ) : ?>
	<p><?php esc_html_e( 'XML-RPM and WordPress REST API endpoint for requesting user resources will be disabled for all Network Sites if you disable in Network Admin Screen. If you want to disable them individually for a Site, you need to configure in the Site Admin Screen you want disable them instead of disabling them in the Network Admin Screen.', 'wp-kusanagi' ); ?></p>
<?php endif; ?>
