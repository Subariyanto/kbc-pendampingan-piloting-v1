const fs = require('fs')
let s = fs.readFileSync('src/pages/KodeAktivasiPage.jsx', 'binary')
// strip common corrupt emoji prefix bytes from buttons
s = s.replace(/dY"[\x80-\xff]*/g, '')
s = s.replace(/dY\-[\x80-\xff]*/g, '')
s = s.replace(/[\x80-\xff]+\s*Terbitkan Kode/g, ' Terbitkan Kode')
s = s.replace(/[\x80-\xff]+\s*Aktif/g, ' Aktif')
fs.writeFileSync('src/pages/KodeAktivasiPage.jsx', s, 'binary')
console.log('done2')
