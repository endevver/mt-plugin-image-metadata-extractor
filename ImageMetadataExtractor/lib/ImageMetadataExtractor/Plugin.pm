package ImageMetadataExtractor::Plugin;

use strict;
use warnings;
use MT::Asset::Image;
use Image::ExifTool qw( :Public );

sub upload_image_callback {
    # "Shift" the data off of @_ so that $params collects all of the 
    # parameters in the callback. The following does not properly populate
    # $params, so it must be shifted instead.
    #my ($cb, $params) = @_;
    my $cb = shift;
    my $params = shift;

    my $asset = $params->{Asset};

    # The upload image callback should only be firing for assets of the 
    # "image" class, so everything should work... but check anyway.
    return 1 if $asset && $asset->class ne 'image';

    _extract_meta($asset);

    1;
}

# List Actions and Page Actions both call this function.
sub list_action {
    my ($app) = @_;
    $app->validate_magic or return;

    # Many assets may have been selected and submitted. Loop through all of 
    # them and process each one.
    my @asset_ids = $app->param('id');
    foreach my $asset_id (@asset_ids) {
        my $asset = MT->model('asset')->load($asset_id);

        if ($asset->class eq 'image') {
            _extract_image_meta($asset);
        } elsif ($asset->class eq 'audio') {
            _extract_audio_meta($asset);
        }
    }

    $app->call_return;
}

# Extract the EXIF and IPTC metadata from the image and save it to the asset
# in meta fields.
sub _extract_meta {
    my ($asset) = @_;

    # Collect the EXIF and IPTC metadata
    my $info = ImageInfo(
        $asset->file_path,
        {
            CoordFormat => "%.9f", # GPS coordinates
            DateFormat  => "%Y-%m-%d %H:%M:%S",
        }
    );

    # Write that EXIF and IPTC meta to the MT::Asset::Image meta fields. Note 
    # that several of these have fallback values, which may or may not exist 
    # in the EXIF depending upon the application that wrote the image file.
    # Refer to http://www.digicamsoft.com/exif22/exif22/html/exif22_1.htm for
    # information on these fields, the preferred fields, and the fallbacks.
    
    # Camera data
    $asset->camera_make( $info->{'Make'} );
    $asset->camera_model( $info->{'Model'} );
    $asset->lens( 
        $info->{'Lens'} 
        || $info->{'LensInfo'} 
    );
    $asset->focal_length( $info->{'FocalLength'} );
    $asset->focal_length_in_35mm( 
        $info->{'FocalLengthIn35mmFormat'} 
        # FocalLength35efl seems to miscalculate the focal length, so we 
        # won't use that as a fallback.
        #|| $info->{'FocalLength35efl'} 
    );

    # Auto, Manual, Shutter priority, etc.
    $asset->exposure_mode( 
        $info->{'ExposureMode'} 
        || $info->{'ExposureProgram'} 
    );
    $asset->metering_mode( $info->{'MeteringMode'} );
    $asset->shutter_speed( 
        $info->{'ShutterSpeedValue'} 
        || $info->{'ShutterSpeed'} 
        || $info->{'ExposureTime'}
    );
    $asset->aperture( 
        $info->{'ApertureValue'} 
        || $info->{'Aperture'} 
        || $info->{'FNumber'} 
    );
    $asset->iso( $info->{'ISO'} );
    $asset->exposure_compensation( 
        $info->{'ExposureCompensation'} 
        || $info->{'ExposureBiasValue'} 
    );
    $asset->white_balance( $info->{'WhiteBalance'} );
    $asset->flash_fired( 
        $info->{'FlashFired'} 
        || $info->{'FlashFunction'} 
    );
    
    $asset->original_datetime( 
        $info->{'DateTimeOriginal'} 
        || $info->{'CreateDate'} 
        || $info->{'ModifyDate'}
    );

    $asset->gps_latitude( $info->{'GPSLatitude'} );
    $asset->gps_longitude( $info->{'GPSLongitude'} );
    $asset->gps_altitude( $info->{'GPSAltitude'} );

    # User-supplied description data. Fall back to many other values, 
    # including IPTC, to try and populate these as well as possible because
    # they are probably the most-likely fields to be used.
    $asset->document_title( 
        $info->{'Title'} 
        || $info->{'ObjectName'} 
    );
    $asset->creator( 
        $info->{'By-line'} 
        || $info->{'Artist'} 
        || $info->{'Creator'} # an IPTC field
    );
    $asset->creator_title( 
        $info->{'By-lineTitle'} 
        || $info->{'AuthorsPosition'}
    );
    $asset->image_description( 
        $info->{'ImageDescription'} 
        || $info->{'CaptionAbstract'}
        || $info->{'Description'} # an IPTC field
    );

    # Rating is a bit arbitrary -- it's a numberic rating but apparently 
    # there is no predefined scale. Adobe uses a 5-star scale, FWIW.
    $asset->rating( $info->{'Rating'} || '' );

    $asset->description_writer( 
        $info->{'Writer-Editor'} 
        || $info->{'CaptionWriter'} # an IPTC field
    );

    # Semicolons or commas are accepted keyword separators, but there 
    # doesn't appear to be any strict enforcement of this.
    $asset->keywords( $info->{'Keywords'} ); # an IPTC field

    $asset->copyright_notice( 
        $info->{'CopyrightNotice'} 
        || $info->{'Copyright'} 
        || $info->{'Rights'} 
    );

    # The Copyright Status field can be true (copyrighted), false (public 
    # domain), or unset. The true/copyrighted and false/public domain is 
    # taken from Adobe Photoshop's File Info window.
    my $copyright_status;
    if ($info->{'CopyrightStatus'} && $info->{'CopyrightStatus'} eq 'True') {
        $copyright_status = 'Copyrighted';
    }
    elsif ($info->{'CopyrightStatus'} && $info->{'CopyrightStatus'} eq 'False') {
        $copyright_status = 'Public Domain';
    }
    $asset->copyright_status( $copyright_status );

    $asset->copyright_info_url( $info->{'URL'} );

    # IPTC metadata should be included because it's internationally-
    # recognized press-used fields. Only IPTC Core is saved.
    # http://iptc.cms.apa.at/cms/site/index.html?channel=CH0099

    # A note (mostly for Jay, ha): I didn't use a prototype to assign all of 
    # these values because I wanted to maintain parity with the IPTC spec as
    # best I could: the meta field names used here aligns with the IPTC 
    # generic specification "name" (dirified),  and the value coming from 
    # $info corresponds to the IPTC XMP implementation property ID.

    $asset->iptc_description( $info->{'Description'} );
    $asset->iptc_headline( $info->{'Headline'} );
    $asset->iptc_keywords( $info->{'Keywords'} );

    # The following should only contain IPTC Subject NewsCode Controlled 
    # Vocabulary Values (http://www.newscodes.org)
    $asset->iptc_intellectual_genre( $info->{'IntellectualGenre'} );
    $asset->iptc_scene_code( $info->{'Scene'} );
    $asset->iptc_subject_code( $info->{'SubjectCode'} );

    $asset->iptc_date_created( $info->{'DateCreated'} );
    $asset->iptc_description_writer( $info->{'CaptionWriter'} );
    $asset->iptc_instructions( $info->{'Instructions'} );
    $asset->iptc_job_id( $info->{'TransmissionReference'} );
    $asset->iptc_title( $info->{'title'} );
    $asset->iptc_copyright_notice( $info->{'rights'} );
    $asset->iptc_creator( $info->{'creator'} );
    $asset->iptc_creator_job_title( $info->{'AuthorsPosition'} );
    $asset->iptc_credit_line( $info->{'Credit'} );
    $asset->iptc_rights_usage_terms( $info->{'UsageTerms'} );
    $asset->iptc_source( $info->{'Source'} );
    $asset->iptc_creator_address( $info->{'CreatorAddress'} );
    $asset->iptc_creator_city( $info->{'CreatorCity'} );

    # The "region" is typically displayed as "State/Province," but 
    # "region" is the IPTC proper name.
    $asset->iptc_creator_region( $info->{'CreatorRegion'} );

    $asset->iptc_creator_country( $info->{'CreatorCountry'} );
    $asset->iptc_creator_postal_code( $info->{'CreatorPostalCode'} );

    # Comma-separated email addresses, phone numbers, and URLs are 
    # valid, so the field should be bigger than a string.
    $asset->iptc_creator_email( $info->{'CreatorWorkEmail'} );
    $asset->iptc_creator_phone( $info->{'CreatorWorkPhone'} );
    $asset->iptc_creator_url( $info->{'CreatorWorkURL'} );

    # The following are legacy fields, which have since become part of 
    # IPTC Extension. But to be clear, they are legacy fields, not 
    # deprecated fields, so we'll include them. The following are intended to 
    # be fields about the event, location, or activity.
    # "Sublocation" could be an area of a city or a natural monument, for
    # exmaple.
    $asset->iptc_sublocation( $info->{'Location'} );
    $asset->iptc_city( $info->{'City'} );
    $asset->iptc_state( $info->{'State'} );
    $asset->iptc_country( $info->{'Country'} );

    # 2-3 letter ISO 3166 Country Code of the Country shown in this image
    $asset->iptc_country_code( $info->{'CountryCode'} );

    # Finally, save all of the data.
    $asset->save or die $asset->errstr;
}

1;

__END__
