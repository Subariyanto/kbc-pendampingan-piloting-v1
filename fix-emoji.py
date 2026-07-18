import re
with open('src/pages/KodeAktivasiPage.jsx','rb') as f:
    s = f.read()
s = re.sub(rb'dY"[\x80-\xff]*\s*Import Excel', b'Import Excel', s)
s = re.sub(rb'dY"[\x80-\xff]*\s*Import JSON', b'Import JSON', s)
s = re.sub(rb'dY"[\x80-\xff]*\s*Template Excel', b'Template Excel', s)
s = re.sub(rb'dY"[\x80-\xff]*\s*Export', b'Export', s)
s = re.sub(rb'dY\-[\x80-\xff]*\s*Cetak', b'Cetak', s)
s = re.sub(rb'dY"[\x80-\xff]*\s*Salin Semua', b'Salin Semua', s)
s = re.sub(rb'[\x80-\xff]+\s*Terbitkan Kode', b'Terbitkan Kode', s)
s = re.sub(rb'[\x80-\xff]+\s*Aktif', b'Aktif', s)
with open('src/pages/KodeAktivasiPage.jsx','wb') as f:
    f.write(s)
print('ok')
