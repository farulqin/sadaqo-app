-- =====================================================================
-- Kumpulan query SADAQO untuk lampiran laporan (MySQL / MariaDB di Laragon)
-- Jalankan satu per satu di HeidiSQL / phpMyAdmin, lalu screenshot hasilnya.
-- =====================================================================

-- Q1. Program aktif beserta kategori dan persentase pencapaian (JOIN + perhitungan)
SELECT c.id, c.title, k.label AS kategori, c.target_amount, c.collected_amount,
       ROUND(c.collected_amount / c.target_amount * 100, 1) AS persen_tercapai,
       c.deadline
FROM campaigns c
JOIN categories k ON k.id = c.category_id
WHERE c.status = 'active'
ORDER BY persen_tercapai DESC;

-- Q2. Total donasi sukses per kategori program (JOIN + GROUP BY + SUM)
SELECT k.label AS kategori, COUNT(d.id) AS jumlah_donasi, SUM(d.amount) AS total_donasi
FROM donations d
JOIN campaigns c ON c.id = d.campaign_id
JOIN categories k ON k.id = c.category_id
WHERE d.status = 'success'
GROUP BY k.id, k.label
ORDER BY total_donasi DESC;

-- Q3. Lima donatur dengan total donasi terbesar (tanpa donasi anonim)
SELECT u.name, u.email, COUNT(d.id) AS jumlah_donasi, SUM(d.amount) AS total
FROM donations d
JOIN users u ON u.id = d.user_id
WHERE d.status = 'success' AND d.is_anonymous = 0
GROUP BY u.id, u.name, u.email
ORDER BY total DESC
LIMIT 5;

-- Q4. Donasi per bulan 12 bulan terakhir (fungsi tanggal)
SELECT DATE_FORMAT(d.created_at, '%Y-%m') AS bulan, COUNT(*) AS jumlah, SUM(d.amount) AS total
FROM donations d
WHERE d.status = 'success' AND d.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY bulan
ORDER BY bulan;

-- Q5. Distribusi metode pembayaran (LEFT JOIN ke penyedia)
SELECT d.payment_method, COALESCE(p.name, 'QRIS') AS penyedia, COUNT(*) AS jumlah, SUM(d.amount) AS total
FROM donations d
LEFT JOIN payment_providers p ON p.id = d.payment_provider_id
GROUP BY d.payment_method, penyedia
ORDER BY jumlah DESC;

-- Q6. Program yang belum menerima donasi sama sekali (LEFT JOIN ... IS NULL)
SELECT c.id, c.title, c.status
FROM campaigns c
LEFT JOIN donations d ON d.campaign_id = c.id
WHERE d.id IS NULL;

-- Q7. Jumlah pengguna per peran (GROUP BY)
SELECT role, COUNT(*) AS jumlah FROM users GROUP BY role;

-- Q8. Pengguna yang sedang dibanned dari Komunitas
SELECT id, name, email, strikes, banned_until
FROM users
WHERE banned_until IS NOT NULL AND banned_until > NOW()
ORDER BY banned_until DESC;

-- Q9. Laporan Komunitas yang menunggu tinjauan admin (JOIN banyak tabel)
SELECT r.id, r.reason, r.status,
       rep.name AS pelapor,
       au.name  AS penulis,
       COALESCE(p.body, c.body) AS isi_konten,
       IF(r.comment_id IS NULL, 'post', 'komentar') AS jenis,
       r.created_at
FROM community_post_reports r
JOIN users rep ON rep.id = r.reporter_id
LEFT JOIN community_posts p    ON p.id = r.post_id
LEFT JOIN community_comments c ON c.id = r.comment_id
LEFT JOIN users au ON au.id = COALESCE(p.user_id, c.user_id)
WHERE r.status = 'pending'
ORDER BY r.id DESC;

-- Q10. Post Komunitas dengan jumlah apresiasi dan komentar (subquery + agregasi)
SELECT p.id, u.name AS penulis, p.category, LEFT(p.body, 60) AS cuplikan,
       (SELECT COUNT(*) FROM community_post_likes l WHERE l.post_id = p.id) AS apresiasi,
       (SELECT COUNT(*) FROM community_comments cm WHERE cm.post_id = p.id) AS komentar,
       p.is_pinned
FROM community_posts p
JOIN users u ON u.id = p.user_id
WHERE p.is_hidden = 0
ORDER BY apresiasi DESC, komentar DESC
LIMIT 10;

-- Q11. Hasil polling: jumlah suara dan persentase per pilihan (JOIN + window function)
SELECT pl.question, o.label AS pilihan, COUNT(v.id) AS suara,
       ROUND(COUNT(v.id) * 100 / NULLIF(SUM(COUNT(v.id)) OVER (PARTITION BY pl.id), 0), 1) AS persen
FROM community_polls pl
JOIN community_poll_options o ON o.poll_id = pl.id
LEFT JOIN community_poll_votes v ON v.option_id = o.id
GROUP BY pl.id, pl.question, o.id, o.label
ORDER BY pl.id, o.sort_order;

-- Q12. Pelanggaran per jenis (dasar sanksi peringatan dan banned)
SELECT type AS jenis_pelanggaran, COUNT(*) AS jumlah
FROM community_violations
GROUP BY type
ORDER BY jumlah DESC;

-- Q13. Laporan penyaluran dana yang disetujui: dana terkumpul vs tersalurkan
SELECT c.title, c.collected_amount AS terkumpul,
       SUM(r.distributed_amount) AS tersalurkan,
       SUM(r.beneficiaries) AS penerima_manfaat
FROM campaign_reports r
JOIN campaigns c ON c.id = r.campaign_id
WHERE r.status = 'approved'
GROUP BY c.id, c.title, c.collected_amount;

-- Q14. 15 aktivitas terakhir di sistem (log audit admin)
SELECT a.created_at, a.kind, a.text, u.name AS pelaku
FROM activity_logs a
LEFT JOIN users u ON u.id = a.user_id
ORDER BY a.id DESC
LIMIT 15;
