<?php
		if ( ! defined( 'ABSPATH' ) ) exit; 

		$device_id = isset( $_GET['device_id'] ) && $_GET['device_id'] ? (int)$_GET['device_id'] : 0;
		if ( $device_id ) {
			$update = true;
			$device = $this->modules[$_GET['tab']]->get_device( $device_id );
			$groups = $this->modules[$_GET['tab']]->get_device_relation_groups( $device_id );
			$group_ids = $this->modules[$_GET['tab']]->filtering_by_property( $groups, 'group_id' );
		} else {
			$update = false;
			$device = '';
			$group_ids = array();
		}
		$list_page_url = remove_query_arg( array( 'action', 'device_id' ) );
		$groups = $this->modules[$_GET['tab']]->get_groups();
?>
		<table class="form-table">
			<tr>
				<th><?php _e( 'Device Name', 'wp-kusanagi' ); ?></th>
				<td><input type="text" name="device_name" size="30" value="<?php echo isset( $device->device_name ) ? esc_attr( $device->device_name ) : ''; ?>" /></td>
			</tr>
			<tr>
				<th><?php _e( 'Keyword', 'wp-kusanagi' ); ?></th>
				<td><input type="text" name="keyword" size="30" value="<?php echo isset( $device->keyword ) ? esc_attr( $device->keyword ) : ''; ?>"  /></td>
			</tr>
			<tr>
				<th><?php _e( 'Group', 'wp-kusanagi' ); ?></th>
				<td>
					<input type="hidden" name="device_group" value="0" />
<?php
if ( $groups ) :
?>
					<ul>
<?php
	foreach ( $groups as $group ) :
		$checked = in_array( $group->group_id, $group_ids ) ? ' checked="checked"' : '';
?>
						<li>
							<label for="device_group-<?php echo esc_attr( $group->group_id ); ?>">
								<input type="checkbox" name="device_group[]" id="device_group-<?php echo esc_attr( $group->group_id ); ?>" value="<?php echo esc_attr( $group->group_id ); ?>"<?php echo $checked; ?> />
								<?php echo esc_html( $group->group_name ); ?>
							</label>
						</li>
<?php
	endforeach;
?>
					</ul>
<?php
endif;
?>
				</td>
			</tr>
		</table>
