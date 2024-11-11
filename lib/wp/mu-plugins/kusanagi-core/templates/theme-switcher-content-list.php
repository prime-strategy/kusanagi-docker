<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$this->form_submit = false;
$device            = $this->modules[ sanitize_text_field( $_GET['tab'] ) ]->do_activation_module_hook();
$groups            = new KUSANAGI_Device_Group_List_Table();
$groups->prepare_items();
$items = new KUSANAGI_Device_List_Table();
$items->prepare_items();

$add_group_url  = add_query_arg( array( 'action' => 'add_group' ) );
$add_device_url = add_query_arg( array( 'action' => 'add_device' ) );
?>
	<div id="disable-theme-switch">
		<input type="hidden" name="theme_switcher_disable" value="0">
		<label for="theme-switcher-disable">
			<input type="checkbox" name="theme_switcher_disable" id="theme-switcher-disable" value="1"<?php echo get_option( 'theme_switcher_disable', 0 ) ? 'checked="checked"' : ''; ?>>
			<?php esc_html_e( 'Disable switch theme', 'wp-kusanagi' ); ?>
		</label>
		<input type="submit" name="update-kusanagi-settings" id="update-kusanagi-settings" class="button button-primary" value="<?php esc_html_e( 'Save Changes', 'wp-kusanagi' ); ?>">
	</div>
	<h4><?php esc_html_e( 'Group', 'wp-kusanagi' ); ?> <a href="<?php echo esc_url( $add_group_url ); ?>" class="add-new-h2"><?php esc_html_e( 'Add New', 'wp-kusanagi' ); ?></a></h4>
	<?php $groups->display(); ?>
	<h4><?php esc_html_e( 'Device', 'wp-kusanagi' ); ?> <a href="<?php echo esc_url( $add_device_url ); ?>" class="add-new-h2"><?php esc_html_e( 'Add New', 'wp-kusanagi' ); ?></a></h4>
	<?php $items->display(); ?>
