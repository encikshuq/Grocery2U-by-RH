# Grocery2U v1.2.5 Receipt Storage Update

Update ini tambah flow resit:
- Upload / ambil gambar resit
- Preview resit dalam app
- Download semula resit
- Share resit
- Delete resit
- Export rekod resit JSON
- Storage usage meter 50MB/family

Production storage:
- Supabase Storage bucket: `receipts`
- Database table: `receipts`
- Suggested path: `receipts/{family_id}/{yyyy}/{mm}/receipt_{receipt_id}.webp`

Nota: Demo HTML menyimpan fail dalam browser localStorage. Versi production perlu upload fail sebenar ke Supabase Storage dan simpan path dalam table `receipts`.
