#!/usr/bin/python
from __future__ import print_function

import plistlib
import re
import string
import subprocess
import os.path


_PLISTBUDDY = '/usr/libexec/PlistBuddy'
_UUIDGEN = '/usr/bin/uuidgen'
_DOCK_PLIST = 'Library/Preferences/com.apple.dock.plist'

_PERSISTENT_APPS = 'persistent-apps'
_PERSISTENT_OTHERS = 'persistent-others'
_DOCK_SECTIONS = [_PERSISTENT_APPS, _PERSISTENT_OTHERS]

_FILE_TYPE_APPLICATION = 41
_FILE_TYPE_PLAIN_FILE = 32
_FILE_TYPE_DIRECTORY = 2

_TILE_TYPE_FILE = 'file-tile'
_TILE_TYPE_DIRECTORY = 'directory-tile'
_TILE_TYPE_URL = 'url-tile'


def generate_guid():
    global _UUIDGEN

    return subprocess.check_output([_UUIDGEN])


def dock_section_title(section):
    return string.capwords(section.replace('-', ' '))


def read_dock_plist(path):
    global _PLISTBUDDY
    global _DOCK_PLIST

    dock_plist = os.path.join(path, _DOCK_PLIST)
    dock_xml = subprocess.check_output([_PLISTBUDDY, '-x', '-c', 'print',
                                        dock_plist])

    return plistlib.readPlistFromString(dock_xml)


def find_tile(dock, label):
    global _DOCK_SECTIONS

    index = None
    section = None

    for ds in _DOCK_SECTIONS:
        for i in xrange(len(dock[ds])):
            if dock[ds][i]['tile-data']['file-label'] == label:
                index = i
                section = ds
                break

        if index is not None:
            break

    return (section, index)


def list_dock(dock):
    global _DOCK_SECTIONS

    for ds in _DOCK_SECTIONS:
        print(dock_section_title(ds))

        for i in xrange(len(dock[ds])):
            tile = dock[ds][i]['tile-data']
            label = tile['file-label']
            path = tile['file-data']['_CFURLString']
            print(i, label, path, sep='\t')


def _create_application_tile(dock, path, label):
    global _FILE_TYPE_APPLICATION
    global _TILE_TYPE_FILE

    app_tile = {
        'GUID': generate_guid(),
        'tile-data': {
            'file-data': {
                '_CFURLString': path,
                '_CFURLStringType': 0
            },
            'file-label': label,
            'file-type': _FILE_TYPE_APPLICATION
        },
        'tile-type': _TILE_TYPE_FILE
    }

    return app_tile


def add_tile(dock, path, label=None, position=None):

    app_re = re.compile('\.app/?$', re.I)
    url_re = re.compile('\w+://', re.I)
    slash_re = re.compile('/$')

    # Check to see if we are adding an application
    if app_re.search(path):

        # Set the label to the applicaton name
        if label is None:
            label = os.path.basename(app_re.sub('', path))

        new_tile = _create_application_tile(dock, slash_re.sub(path), label)

    # Check to see if we are adding a URL
    elif url_re.match(path):
        section = 'persistent-others'
        tile_type = 'url-tile'

        # Just set the label to the full url
        if label is None:
            label = path

    # Check to see if we are adding a file or directory
    elif os.path.exists(path):
        section = 'persistent-others'

        if os.path.isdir(path):
            tile_type = 'directory-tile'
        else:
            tile_type = 'file-tile'

        if label is None:
            label = os.path.basename(re.sub('/$', '', path))

    # Given an invalid object
    else:
        pass  # Throw exception


if __name__ == '__main__':
    mydock = read_dock_plist('/Users/adriantrunzo')
    list_dock(mydock)
    print(find_tile(mydock, 'Spotify'))
