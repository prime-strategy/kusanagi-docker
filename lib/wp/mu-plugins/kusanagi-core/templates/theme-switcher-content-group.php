<?php
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$group_id = isset( $_GET['group_id'] ) && $_GET['group_id'] ? sanitize_text_field( $_GET['group_id'] ) : 0;

if ( $group_id ) {
	$update = true;
	$group  = $this->modules[ sanitize_text_field( $_GET['tab'] ) ]->get_group( $group_id );
} else {
	$update = false;
	$group  = '';
}

$list_page_url = remove_query_arg( array( 'action', 'id' ) );
?>
		<table class="form-table">
			<tr>
				<th><?php esc_html_e( 'Group Name', 'wp-kusanagi' ); ?></th>
				<td><input type="text" name="group_name" size="30" value="<?php echo isset( $group->group_name ) ? esc_html( $group->group_name ) : ''; ?>" /></td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Theme', 'wp-kusanagi' ); ?></th>
				<td>
					<select name="theme">
						<option value=""><?php esc_html_e( 'Use current theme', 'wp-kusanagi' ); ?></option>
<?php
if ( isset( $this->modules['theme-switcher']->available_themes ) ) :
	foreach ( $this->modules['theme-switcher']->available_themes as $key => $theme_object ) :
		if ( get_option( 'stylesheet' ) !== $key ) :
			if ( is_object( $theme_object ) ) {
				$name = $theme_object->__get( 'name' );
			} else {
				$name = $theme_object['Name'];
			}
			?>
						<option value="<?php echo esc_attr( $key ); ?>"<?php echo $group->theme === $key ? ' selected="selected"' : ''; ?>><?php echo esc_html( $name ); ?></option>
			<?php
		endif;
	endforeach;
endif;
?>
					</select>
				</td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Slug', 'wp-kusanagi' ); ?></th>
				<td><input type="text" name="slug" size="10" value="<?php echo isset( $group->slug ) ? esc_html( $group->slug ) : ''; ?>" /></td>
			</tr>
			<tr>
				<th><?php esc_html_e( 'Priority', 'wp-kusanagi' ); ?></th>
				<td><input type="number" name="priority" size="2" value="<?php echo isset( $group->priority ) ? esc_html( $group->priority ) : ''; ?>" /></td>
			</tr>
		</table>
