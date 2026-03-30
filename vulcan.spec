# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec for Vulcan I
Build: pyinstaller vulcan.spec
Output: dist/Vulcan I.app  (macOS)  or  dist/Vulcan I/  (Windows/Linux)
"""

import sys
from pathlib import Path

block_cipher = None

a = Analysis(
    ['vulcan.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('sprites',  'sprites'),
        ('sound',    'sound'),
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Vulcan I',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,           # no terminal window
    icon='vulcan.icns',      # macOS / Windows icon
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Vulcan I',
)

# macOS .app bundle
if sys.platform == 'darwin':
    app = BUNDLE(
        coll,
        name='Vulcan I.app',
        icon='vulcan.icns',
        bundle_identifier='com.kennycason.vulcan',
        info_plist={
            'NSHighResolutionCapable': True,
            'CFBundleShortVersionString': '1.0.0',
            'CFBundleName': 'Vulcan I',
        },
    )
