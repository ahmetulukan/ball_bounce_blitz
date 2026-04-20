# Ball Bounce Blitz - Oyun Spesifikasyonu

## Genel Bakış
- **Tür**: Arcade/reflex oyunu (Flame engine, Flutter)
- **Platform**: iOS, Android, Web

## Hedef Kullanıcılar
- Mobil kullanıcılar için hızlı, eğlenceli oyun deneyimi

## Temel Mekanikler

### 1. Paddle Kontrolü
- Yatay hareket, mouse/touch ile
- Ekranın alt bölümünde sabit

### 2. Top (Ball)
- Sürekli yukarı doğru sekme
- Paddle'dan sekmesi = +1 puan
- Duvarlardan sekmesi = fizik
- Ekran dışına çıkması = oyun bitişi

### 3. Düşmanlar (Enemies)
- Farklı renk/şekil, yukarı doğru hareket
- Top ile temas = can kaybı veya oyun bitişi

### 4. Zorluk Artışı
- Zamanla düşman hızı artar
- Puan ile yeni düşman türleri

## MVP Features
1. Paddle hareketi
2. Top fiziği ve sekme
3. Basit düşman
4. Skor sistemi
5. Oyun bitişi ve restart

## Teknik
- Flutter + Flame
- State management: flame built-in
- Collision detection: Flame hitbox
