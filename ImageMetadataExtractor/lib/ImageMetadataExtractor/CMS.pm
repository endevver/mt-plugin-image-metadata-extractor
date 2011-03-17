package ImageMetadataExtractor::CMS;

use strict;
use warnings;
use MT::Asset::Image;
use MT::Util qw( format_ts );

# These fields are set in add_asset_image_meta and used in _field_wrapper.
our $show_empty_fields;
our $show_map_preview;

# Display the extracted metadata on the Edit Asset page.
sub add_asset_image_meta {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Only update the page if this is an Image asset.
    return 1 if $param->{asset_type} ne 'image';

    my $plugin  = $cb->plugin;
    # Populate $show_empty_fields to be used later with _field_wrapper. Same
    # with $show_map_preview.
    my $config = $plugin->get_config_hash( 'blog:'.$param->{blog_id} );
    $show_empty_fields = $config->{'show_empty_fields'};
    $show_map_preview  = $config->{'show_map_preview'};

    my $blog      = $app->blog;
    my $asset_pkg = MT->model('asset');

    my $asset = $asset_pkg->load( $param->{id} )
      or die sprintf( "Could not load asset ID %s: %s",
                      $param->{id}, $asset_pkg->errstr );

    # Break the image metadata into three tabs: camera data, description, and 
    # IPTC Core. Build each of those then place them into an app:SettingGroup, 
    # and insert that onto the page.

    my $camera_meta_field = $tmpl->createElement(
        'app:setting',
        {
           id          => 'camera_metadata',
           label       => 'Camera Metadata',
           label_class => 'text-top',
        }
    );

    # The original_datetime field needs to be massaged to display nicely.
    my $dt = format_ts( "%Y-%m-%d %H:%m:%S", $asset->original_datetime )
        if $asset->original_datetime;

    $camera_meta_field->innerHTML(
        _map_preview($asset->gps_latitude, $asset->gps_longitude)
        . _field_wrapper('Camera Make', $asset->camera_make)
        . _field_wrapper('Camera Model', $asset->camera_model)
        . _field_wrapper('Lens', $asset->lens)
        . _field_wrapper('Focal Length', $asset->focal_length)
        . _field_wrapper('Focal Length (in 35mm)', $asset->focal_length_in_35mm)
        . _field_wrapper('Exposure Mode', $asset->exposure_mode)
        . _field_wrapper('Metering Mode', $asset->metering_mode)
        . _field_wrapper('Shutter Speed', $asset->shutter_speed)
        . _field_wrapper('Aperture', $asset->aperture)
        . _field_wrapper('ISO', $asset->iso)
        . _field_wrapper('Exposure Compensation', $asset->exposure_compensation)
        . _field_wrapper('White Balance', $asset->white_balance)
        . _field_wrapper('Flash Fired', $asset->flash_fired)
        . _field_wrapper('Original Date/Time', $dt)
        . _field_wrapper('GPS Latitude', $asset->gps_latitude)
        . _field_wrapper('GPS Longitude', $asset->gps_longitude)
        . _field_wrapper('GPS Altitude', $asset->gps_altitude)
    );

    if ($camera_meta_field->innerHTML eq '') {
        $camera_meta_field->innerHTML('<p>No metadata was found.</p>');
    }

    my $desc_meta_field = $tmpl->createElement(
        'app:setting',
        {
           id          => 'description_metadata',
           label       => 'Description Metadata',
           label_class => 'text-top hidden',
        }
    );

    $desc_meta_field->innerHTML(
        _field_wrapper('Document Title', $asset->document_title)
        . _field_wrapper('Creator', $asset->creator)
        . _field_wrapper('Creator Title', $asset->creator_title)
        . _field_wrapper('Image Description', $asset->image_description)
        . _field_wrapper('Description Writer', $asset->description_writer)
        . _field_wrapper('Keywords', $asset->keywords)
        . _field_wrapper('Copyright Notice', $asset->copyright_notice)
        . _field_wrapper('Copyright Status', $asset->copyright_status)
        . _field_wrapper('Copyright Info URL', $asset->copyright_info_url)
        . _field_wrapper('Rating', $asset->rating)
    );

    if ($desc_meta_field->innerHTML eq '') {
        $desc_meta_field->innerHTML('<p>No metadata was found.</p>');
    }

    my $iptc_meta_field = $tmpl->createElement(
        'app:setting',
        {
           id          => 'iptc_metadata',
           label       => 'IPTC Metadata',
           label_class => 'text-top hidden',
        }
    );

    # The original_datetime field needs to be massaged to display nicely.
    $dt = ''; # Reset os that the $asset->original_datetime doesn't get used.
    $dt = format_ts( "%Y-%m-%d %H:%m:%S", $asset->iptc_date_created )
        if $asset->iptc_date_created;

    $iptc_meta_field->innerHTML(
        _field_wrapper('Description', $asset->iptc_description)
        . _field_wrapper('Headline', $asset->iptc_headline)
        . _field_wrapper('Keywords', $asset->iptc_keywords)
        . _field_wrapper('Intellectual Genre', $asset->iptc_intellectual_genre)
        . _field_wrapper('Scene Code', $asset->iptc_scene_code)
        . _field_wrapper('Subject Code', $asset->iptc_subject_code)
        . _field_wrapper('Date Created', $dt)
        . _field_wrapper('Description Writer', $asset->iptc_description_writer)
        . _field_wrapper('Instructions', $asset->iptc_instructions)
        . _field_wrapper('Job ID', $asset->iptc_job_id)
        . _field_wrapper('Title', $asset->iptc_title)
        . _field_wrapper('Copyright Notice', $asset->iptc_copyright_notice)
        . _field_wrapper('Creator', $asset->iptc_creator)
        . _field_wrapper('Creator Job Title', $asset->iptc_creator_job_title)
        . _field_wrapper('Credit Line', $asset->iptc_credit_line)
        . _field_wrapper('Rights Usage Terms', $asset->iptc_rights_usage_terms)
        . _field_wrapper('Source', $asset->iptc_source)
        . _field_wrapper('Creator Addresss', $asset->iptc_creator_address)
        . _field_wrapper('Creator City', $asset->iptc_creator_city)
        . _field_wrapper('Creator Region (State/Province)', $asset->iptc_creator_region)
        . _field_wrapper('Creator Country', $asset->iptc_creator_country)
        . _field_wrapper('Creator Postal Code', $asset->iptc_creator_postal_code)
        . _field_wrapper('Creator Email', $asset->iptc_creator_email)
        . _field_wrapper('Creator Phone', $asset->iptc_creator_phone)
        . _field_wrapper('Creator URL', $asset->iptc_creator_url)
        . _field_wrapper('Sublocation', $asset->iptc_sublocation)
        . _field_wrapper('City', $asset->iptc_city)
        . _field_wrapper('State', $asset->iptc_state)
        . _field_wrapper('Country', $asset->iptc_country)
        . _field_wrapper('Country Code', $asset->iptc_country_code)
    );

    if ($iptc_meta_field->innerHTML eq '') {
        $iptc_meta_field->innerHTML('<p>No metadata was found.</p>');
    }

    # Create the group field to hold all of the meta fields.
    my $group_field = $tmpl->createElement(
        'app:settinggroup',
        {
            id => 'image_metadata',
        }
    );
    
    my $nav = <<"HTML";
<style type="text/css">
/* The fields on the Edit Asset page are all constrained to 300px wide so that 
   the thumbnail will fit. Because the extracted metadata block should fill 
   the width of the page to make good use of the space, the page needs to be
   styled differently to make things work. */
.edit-asset #main-content .asset-metadata {
    float: none;
    width: auto;
}
.edit-asset #main-content .field {
    width: 300px;
    overflow: hidden;
}
fieldset#image_metadata {
    padding-top: 10px;
    clear: both;
}
ul#image_metadata_nav {
    padding-bottom: 2px;
    border-bottom: 3px solid #e7f0f6;
}
ul#image_metadata_nav li {
    display: inline;
    background: #e7f0f6;
    padding: 5px 8px;
    margin: 0 0 0 5px;
    cursor: pointer;
}
ul#image_metadata_nav li.selected {
    background: #90c9ea;
}
ul#image_metadata_nav li:hover { background: #90c9ea; }
.edit-asset #main-content fieldset#image_metadata .field {
    width: auto;
}
.field.image-metadata {
    margin: 2px 0 5px;
}
.field.image-metadata .field-header {
    color: #777;
    margin: 0;
}
.field.image-metadata .field-content p:last-child {
    margin-bottom: 0;
}

.edit-asset #main-content .asset-preview.map-preview .asset-thumb {
    border: 1px solid #000;
    height: 260px;
}
.edit-asset #main-content .asset-preview.map-preview .asset-thumb-inner {
    margin: 0;
    height: 260px;
}
</style>

<mt:Unless tag="ProductName" eq="Melody">
<script type="text/javascript" src="http://localhost/mt435-static/jquery/jquery.js"></script>
</mt:Unless>
<script type="text/javascript">
jQuery(document).ready(function() {
    // When a tab is clicked, show the appropriate data.
    jQuery('ul#image_metadata_nav li').click(function(){
        // Hide all of the fields first
        jQuery('#image_metadata .field-text-top').addClass('hidden');
        jQuery('ul#image_metadata_nav li').removeClass('selected');

        // Remove the "hidden" class for the selected tab
        var selected = jQuery(this).attr('class');
        jQuery('#' + selected + '-field').removeClass('hidden');

        // Style the selected tab slightly
        jQuery(this).addClass('selected');
    });
    
    // When mousing-over the map, zoom in.
    jQuery('img.map-preview-image-1').mouseover(function(){
        jQuery(this).addClass('hidden');
        jQuery('img.map-preview-image-2').removeClass('hidden');
    });
    jQuery('img.map-preview-image-2').mouseout(function(){
        jQuery(this).addClass('hidden');
        jQuery('img.map-preview-image-1').removeClass('hidden');
    });
});
</script>
<ul id="image_metadata_nav">
    <li class="camera_metadata selected">Camera</li>
    <li class="description_metadata">Description</li>
    <li class="iptc_metadata">IPTC</li>
</ul>
HTML

    $group_field->innerHTML($nav);

    # I think I should be able to use $group_field->appendChild here to add 
    # the meta fields to the group, however it doesn't work. Calling 
    # $group_field->appendChild is using MT::Template::Node::appendChild. 
    # Just grabbing the meat of MT::Template::appendChild and using it below 
    # does work, though.
    my $nodes = $group_field->childNodes;
    push @$nodes, $camera_meta_field, $desc_meta_field, $iptc_meta_field;
    $group_field->childNodes($nodes);

    my $tags_field = $tmpl->getElementById('tags')
        or die MT->log('Cannot identify the tags field block in template');

    $tmpl->insertAfter( $group_field, $tags_field )
        or die MT->log('Failed to insert the Camera Metadata field into template.');
}

# This wrapper is based on what is generated by mtapp:Setting, but has been
# reworked a little to support displaying the metadata.
sub _field_wrapper {
    my ($label, $data) = @_;
    
    # If $data is empty and if $show_empty_fields is not checked, just return 
    # now, without creating the field (the user doesn't want to see a blank 
    # field). If $show_empty_fields is checked, proceed and build the field.
    return '' if !$data && !$show_empty_fields;

    # This will wrap the field data in paragraph tags.
    $data = MT->apply_text_filters($data, ['__default__']);

    return qq{
        <div class="field field-left-label pkg image-metadata">
            <div class="field-inner">
                <div class="field-header">
                    $label
                </div>
                <div class="field-content">
                    $data
                </div>
            </div>
        </div>
    };
}

# If GPS coordinates are available we should display a map so the user has some
# context of where the location is.
sub _map_preview {
    my ($lat, $long) = @_;
    
    # If GPS coordinates aren't available there's no point in displaying a map.
    return if !$lat || !$long || !$show_map_preview;
    
    return qq{
        <div class="asset-preview map-preview">
            <div class="asset-thumb">
                <div class="asset-thumb-inner">
                    <img class="map-preview-image-1" src="https://maps.googleapis.com/maps/api/staticmap?markers=$lat,$long&amp;zoom=8&amp;size=260x260&amp;sensor=false" width="260" height="260" />
                    <img class="map-preview-image-2 hidden" src="https://maps.googleapis.com/maps/api/staticmap?markers=$lat,$long&amp;zoom=11&amp;size=260x260&amp;sensor=false" width="260" height="260" />
                </div>
            </div>
        </div>
    };
}

# The user may have enabled the plugin settings to update the asset label, 
# description and/or tags with the extracted meta. Check if those options have 
# been enabled and grab the new field data, if needed. Present it all on the 
# Insert Image dialog screen for the user to further refine.
sub insert_asset_options_param {
    my ($cb, $app, $param, $tmpl) = @_;

    my $asset_pkg = MT->model('asset');
    my $asset = $asset_pkg->load( $param->{asset_id} )
      or die sprintf( "Could not load asset ID %s: %s",
                      $param->{asset_id}, $asset_pkg->errstr );

    my $plugin  = $cb->plugin;
    my $config  = $plugin->get_config_hash( 'blog:'.$param->{blog_id} );
    my $field_name;

    # Copy a field to the asset label?
    if ( $config->{update_asset_label} ) {
        # Try to use the specified field for the asset label. But, if it's 
        # blank fall back to the existing asset label.
        $field_name = $config->{update_asset_label};
        $param->{fname} 
            = eval { $asset->$field_name } || $asset->label;
    }

    # Copy a field to the asset description?
    if ( $config->{update_asset_description} ) {
        # Try to use the specified field for the asset description. But, if 
        # it's blank fall back to the existing asset label.
        $field_name = $config->{update_asset_description};
        $param->{description} 
            = eval { $asset->$field_name } || $asset->description;
    }

    # Copy keywords to asset tags?
    if ( $config->{update_asset_tags} ) {
        if ( eval { $asset->keywords } ) {
            my @keywords = split(/\s*[;,]\s*/, $asset->keywords);
            $param->{tags} = join(', ', @keywords);
        }
    }
}

# The Insert Asset screen doesn't include the variables for the description 
# and tags field, so we can't just populate them. This adds those field 
# variables, so that the param callback can properly supply them.
sub insert_asset_options_source {
    my ($cb, $app, $tmpl) = @_;

    my ($old, $new);

    # Update the Description field by including the description variable.
    $old = q{<textarea name="description" id="file_desc" cols="" rows="" class="full-width short"></textarea>};
    $new = q{<textarea name="description" id="file_desc" cols="" rows="" class="full-width short"><mt:Var name="description" escape="html"></textarea>};
    $$tmpl =~ s/$old/$new/;

    # Update the Tags field by including the tags variable.
    $old = q{<input type="text" name="tags" id="file_tags" class="full-width" value="" mt:watch-change="1" autocomplete="0" />};
    $new = q{<input type="text" name="tags" id="file_tags" class="full-width" value="<mt:Var name="tags" escape="html">" mt:watch-change="1" autocomplete="0" />};
    $$tmpl =~ s/$old/$new/;
}

1;
