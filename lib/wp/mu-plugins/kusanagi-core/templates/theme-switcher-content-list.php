<?php
	if ( ! defined( 'ABSPATH' ) ) exit; 

	$this->form_submit = false;
	$device = $this->modules[$_GET['tab']]->do_activation_module_hook();
	$groups = new KUSANAGI_Device_Group_List_Table();
	$groups->prepare_items();
	$items = new KUSANAGI_Device_List_Table();
	$items->prepare_items();

	$add_group_url = add_query_arg( array( 'action' => 'add_group' ) );
	$add_device_url = add_query_arg( array( 'action' => 'add_device' ) );
?>
	<div id="disable-theme-switch">
		<input type="hidden" name="theme_switcher_disable" value="0">
		<label for="theme-switcher-disable">
			<input type="checkbox" name="theme_switcher_disable" id="theme-switcher-disable" value="1"<?php echo get_option( 'theme_switcher_disable', 0 ) ? 'checked="checked"' : ''; ?>>
			<?php _e( 'Disable switch theme', 'wp-kusanagi' ); ?>
		</label>
		<input type="submit" name="update-kusanagi-settings" id="update-kusanagi-settings" class="button button-primary" value="<?php _e( 'Save Changes', 'wp-kusanagi' ); ?>">
	</div>
	<h4><?php _e( 'Group', 'wp-kusanagi' ); ?> <a href="<?php echo esc_url( $add_group_url ); ?>" class="add-new-h2"><?php _e( 'Add New', 'wp-kusanagi' ); ?></a></h4>
	<?php $groups->display(); ?>
	<h4><?php _e( 'Device', 'wp-kusanagi' ); ?> <a href="<?php echo esc_url( $add_device_url ); ?>" class="add-new-h2"><?php _e( 'Add New', 'wp-kusanagi' ); ?></a></h4>
	<?php $items->display();
