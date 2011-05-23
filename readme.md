# Image Metadata Extractor Overview

The Image Metadata Extractor plugin for Movable Type and Melody provides access to the EXIF and IPTC metadata found in digital photos. 

* Extracted metadata can be viewed on the Edit Asset screen in a simple tabbed format.
* Automatically use metadata to populate the Asset Label, Description, and Tags field during file upload.
* If GPS coordinates are available, a map preview is included on the Edit Asset screen.
* Publish metadata with the familiar `<mt:AssetProperty>` tag.


# Installation #

The latest version of the plugin can be downloaded from the its
[Github repo](https://github.com/endevver/mt-plugin-image-metadata-extractor). [Packaged downloads](https://github.com/endevver/mt-plugin-image-metadata-extractor/downloads) are also available if you prefer.

Installation follows the [standard plugin installation](http://tinyurl.com/easy-plugin-install) procedures.


# Configuration

Image Metadata Extractor has a handful of configuration settings found at the blog level in Tools > Plugins > Image Metadata Extractor > Settings:

* Update Asset Label - During file upload, update the Asset Label with an EXIF or IPTC value extracted from the image. Select the field to copy from.
* Update Asset Description - During file upload, update the Asset Description with an EXIF or IPTC value extracted from the image. Select the field to copy from.
* Update Asset Tags - During file upload, add the EXIF/IPTC keywords extracted from the image to the asset’s Tags field.
* Show Empty Fields - After metadata has been extracted, it can be viewed on the Edit Asset page. If a field has not been populated, should the field name be shown?
* Show Map Preview - If GPS coordinates can be extracted from the metadata, a preview map will be displayed on the Edit Asset page. This feature uses Google Maps to create the map image.


# Usage

Metadata needs to be extracted from images before it can be used or viewed. This plugin provides several ways to extract metadata:

* Upload an image -- metadata is extracted during the file upload process.
* Go to Manage > Assets, select several assets, then pick "Extract Image Metadata" from the "More Actions..." menu.
* Go to Manage > Assets, click an asset to get to the Edit Asset page, then click "Extract Image Metadata" from "Actions" in the sidebar.

Once the metadata is extracted, visit the Edit Asset page to see a tabbed view of the information.

If GPS coordinates were found in the metadata, a map preview will be displayed. Hover your mouse over the map to zoom in closer.


# Template Tags

Access extracted metadata with the [`<mt:AssetProperty>`](http://www.movabletype.org/documentation/appendices/tags/assetproperty.html) tag. This tag may be familiar: it's part of the core Movable Type product, and you may be using it to publish an image's width or height, for example.

The `<mt:AssetProperty>` tag is used with the attribute `property` and specified what property to return, as in the following example:

    <mt:AssetProperty property="camera_make">

Note: these properties only exist for image assets, so you need to be sure your templates properly handle different asset types. Two approaches you might use to handle this:

    <mt:Assets type="image" lastn="5"> ... </mt:Assets>

Note the use of the "type" argument to limit the type of assets returned. Alternatively:

    <mt:If tag="AssetType" eq="image"> ... </mt:If>

Check that the current asset is an image asset before processing it.

## Properties

Image Metadata Extractor adds many more valid properties, listed below.

### Images
Note: a specific camera may not supply all EXIF metadata, a user may not supply all IPTC metadata, and that metadata may be stripped when saving an image from some applications. In other words, metadata may not be available (or may only be partially complete) for a specific image.

* `camera_make` - the manufacturer of the camera.
* `camera_model` - the model of the camera used; note that this is often prepended by the manufacturer name.
* `lens` - the lens on the camera; note that this field is assembled based on the contents of other EXIF fields so the results may not be perfect. Specifically, for DSLR users, note that manufacturer names are not included -- perhaps of note to those who use third-party lenses.
* `focal_length` - the focal length the photo was taken at; "mm" is typically included at the end of this value.
* `focal_length_in_35mm` - The `focal_length` is also reported in 35mm-equivalent terms; "mm" is typically included at the end of this value.
* `exposure_mode` - the exposure mode used to take the photo, such as "program," "aperture priority," or "auto."
* `metering_mode` - the metering mode used to take the photo, such as "spot," "center-weighted," or "multi-segment."
* `shutter_speed` - the shutter speed used to take the photo. The value returned is measured in seconds, such as "3" or "18" (seconds, for a longer exposure), and "1/200" or "1/15" (seconds).
* `aperture` - the aperture used to take the photo.
* `iso` - The ISO equivalent sensitivity used to take the photo.
* `exposure_compensation` - the user-adjusted compensation to the photo; this is reported as a decimal with a leading operation sign, as in "+1.7" or "-0.3." Note that when not used, this field returns blank, *not* "0.0" as you might expect.
* `white_balance` - the named white balancing used to take the photo, such as "auto" or "fluorescent." Note that if custom white balance was set "custom" is returned, not the color temperature and tint.
* `flash_fired` - returns "True" or "False"
* `original_datetime` - the date and time when the photo was taken.
* `gps_latitude` - the latitude reported by the camera GPS, in decimal format.
* `gps_longitude` - the longitude reported by the camera GPS, in decimal format.
* `gps_altitude` - the altitude reported by the camera GPS, in decimal format.

The following is user-supplied metadata, typically entered through an image editing application. Unfortunately, all image editors do not use the same user-facing name for these fields. The following are the EXIF-registered field names.

* `document_title` - often referred to as the "caption" field; this field should provide a brief description of the `image_description` field.
* `creator` - the creator's name.
* `creator_title` - the creator's job title.
* `image_description` - a description of the image contents.
* `description_writer` - the author of the `image_description` field.
* `keywords` - keywords (tags) describing the contents of the image.
* `copyright_notice` - brief details of the copyright owner and usage rights.
* `copyright_status` - the Copyright Status value is "Copyrighted," "Public Domain," or unset.
* `copyright_info_url` - a URL for contacting the copyright owner.
* `rating`

[IPTC](http://www.iptc.org/site/Home/) Core metadata is also extracted, if your image includes it. Refer to the [IPTC Core spec](http://iptc.cms.apa.at/cms/site/index.html?channel=CH0099) for further details about how these fields can be used.

* `iptc_description` - a textual description, including captions, of the items content.
* `iptc_headline` - a brief synopsis of the caption; Headline is not the same as Title.
* `iptc_keywords` - keywords to express the subject of the content.
* `iptc_intellectual_genre` - describes the intellectual, artistic or journalistic characteristic of an item, not specifically it's content; should only contain [IPTC Subject NewsCode Controlled Vocabulary Values](http://www.newscodes.org).
* `iptc_scene_code` - describes the scene of a news content; should only contain [IPTC Subject NewsCode Controlled Vocabulary Values](http://www.newscodes.org).
* `iptc_subject_code` - specifies one or more Subjects from the IPTC Subject-NewsCodes taxonomy to categorize the content; should only contain [IPTC Subject NewsCode Controlled Vocabulary Values](http://www.newscodes.org).
* `iptc_date_created` - designates the date and optionally the time the image was created.
* `iptc_description_writer` - identifier or the name of the person involved in writing, editing or correcting the description of the content.
* `iptc_instructions` - any of a number of instructions from the provider or creator to the receiver of the item.
* `iptc_job_id` - number or identifier for the purpose of improved workflow handling; this is a user created identifier related to the job for which the item is supplied.
* `iptc_title` - a shorthand reference for the item. Title provides a short human readable name which can be a text and/or numeric reference. It is not the same as Headline.
* `iptc_copyright_notice` - contains any necessary copyright notice for claiming the intellectual property for this item and should identify the current owner of the copyright for the item.
* `iptc_credit_line` - the credit to person(s) and/or organisation(s) required by the supplier of the item to be used when published.
* `iptc_rights_usage_terms` - the licensing parameters of the item.
* `iptc_source` - Identifies the original owner of the copyright for the intellectual content of the item.
* `iptc_creator` - contains the name of the person who created the content of this item.
* `iptc_creator_job_title` - contains the job title of the person who created the content of this item.
* `iptc_creator_address` - the creator's contact information: mailing address.
* `iptc_creator_city` - the creator's contact information: city.
* `iptc_creator_region` - the creator's contact information; the "region" is typically displayed as "State/Province," but "region" is the IPTC proper name.
* `iptc_creator_country` - the creator's contact information: country.
* `iptc_creator_postal_code` - the creator's contact information: postal code.
* `iptc_creator_email` - the creator's contact information: a list of comma-separated email addresses is valid for this field.
* `iptc_creator_phone` - the creator's contact information: a list of comma-separated phone numbers is valid for this field.
* `iptc_creator_url` - the creator's contact information: a list of comma-separated URLs is valid for this field.
* `iptc_sublocation` - Name of a sublocation the content is focussing on -- an area of a city or a natural monument, for example.
* `iptc_city` - name of the city the content is focusing on.
* `iptc_state` - name of the subregion of a country -- either called province or state or anything else -- the content is focussing on.
* `iptc_country` - full name of the country the content is focussing on.
* `iptc_country_code` - code of the country the content is focussing on; 2-3 letter ISO 3166 Country Code.

### Audio

* `title` - the track title
* `artist` - the artist who produced the track
* `album` - the album this track appears on
* `year` - the year the track was produced
* `comment` - a general comment field
* `track` - this position this track appears in on its album
* `genre` - the ID3 genre
* `duration` - the track's running time
* `audiobitrate` - the bitrate used to encode the audio


# License

This program is distributed under the terms of the GNU General Public License,
version 2.

# Copyright

Copyright 2011, [Endevver LLC](http://endevver.com). All rights reserved.
