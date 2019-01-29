jQuery(document).ready(function($) {

	var target = $("ul.kusanagi-module-desc li .desc");
	var target_inner = $("ul.kusanagi-module-desc li .textinner");
	var target_length = target.length;
	var line = 3;

	var bp = 782;

	$(window).on( 'load resize', function(){

		var w_width = $(window).width();
		if ( bp < w_width ) {
			autoHeight();
		} else {
			target.css( 'height', 'auto' );
		}

	});

	function autoHeight() {
		for( var i = 0 ; i < Math.ceil( target_length / line ) ; i++ ) {
			var maxHeight = 0;
			for( var j = 0; j < line; j++ ){
				if ( target_inner.eq( i * line + j ).height() > maxHeight ) {
					maxHeight = target_inner.eq( i * line + j ).height();
				}
			}
			for( var k = 0; k < line; k++ ){
				target.eq( i * line + k ).height( maxHeight );
			}
		}
	}
});


function add_rule() {
	var last = jQuery(".replace-row:last");
	var last_id = last.attr('id').replace( 'replaces-row-', '' );
	if ( last_id ) {
		var next = Number( last_id ) + 1;	
		var add = '<tr id="replaces-row-' + next + '" class="replace-row"><td><textarea name="site_cache_life[replaces][' + next + '][target]" size="15" rows="3"></textarea></td><td><textarea name="site_cache_life[replaces][' + next + '][replace]" size="15" rows="3"></textarea></td><td><a href="#" class="button" onclick="delete_rule(' + next + '); return false;">Delete Row</a></td></tr>';
		jQuery( "#replaces-table" ).append( add );

	}
}
function delete_rule( num ) {
	jQuery( "#replaces-row-" + num ).remove();
}
