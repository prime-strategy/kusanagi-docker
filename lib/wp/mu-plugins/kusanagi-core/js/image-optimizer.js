jQuery(function($) {
  var quality = $( "#jpeg_quality" ).val();
  $( "#jpeg_quality_slider" ).slider({
    range: 'min',
    value: quality,
    min: 0,
    max: 100,
    slide: function( event, ui ) {
      $( "#jpeg_quality" ).val( ui.value );
      $( "#quality-value" ).html( ui.value );
    }
  });
});