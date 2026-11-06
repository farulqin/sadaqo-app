# Folder assets

assets/
├── images/          logo dan foto statis
│   ├── logo_sadaqo.png          logo + teks (latar transparan)
│   └── logo_sadaqo_emblem.png   emblem saja, tanpa teks
├── icons/           icon kustom (PNG/SVG) dan sumber launcher icon
│   └── app_icon.png             1024x1024, untuk flutter_launcher_icons
└── illustrations/   ilustrasi empty state, onboarding, dll (kosong dulu)

Aturan: tambah file baru di sini, daftarkan path-nya di
lib/core/constants/app_assets.dart, jangan menulis path langsung di widget.
Icon bawaan Flutter (Icons.xxx) tidak perlu masuk folder ini.
