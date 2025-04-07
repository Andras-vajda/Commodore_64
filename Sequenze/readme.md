# 📦 File ZIP - Sequenze Binarie per Commodore 64

Questa cartella contiene i progetti completi per la generazione di varie sequenze binarie su Commodore 64, creati originalmente negli anni '80 e recentemente adattati a CBM Prg Studio.

## 📂 Contenuto dell'Archivio

| 📄 Progetto       | 📜 Descrizione                                                |
| ---------------- | ------------------------------------------------------------ |
| **ThueMorse**    | Implementazione della sequenza di Thue-Morse (sequenza di parità), con modulo USR() e versione standalone per visualizzazione grafica dei pattern. |
| **BaumSweet**    | Generazione della sequenza di Baum-Sweet tramite DFAO (Deterministic Finite Automaton with Output) con tabella di output esplicita. |
| **RudinShapiro** | Implementazione della sequenza di Golay-Rudin-Shapiro con DFAO ottimizzato tramite output codificato negli stati. |
| **Kolakoski**    | Generazione efficiente della sequenza autodescrittiva di Kolakoski (altamente irregolare e non automatica). |

## 🧠 Caratteristiche Implementative

Ogni progetto include:

- **File BASIC** per l'interfaccia utente
- **Codice Assembly 6510** ottimizzato
- **File progetto CBM (.cbmprj)** per un facile utilizzo in CBM Prg Studio

Le implementazioni sono strutturate per massima efficienza e modularità, con diversi approcci algoritmici:

- **Thue-Morse**: Forma chiusa con LUT (lookup table) compatta
- **Baum-Sweet/Rudin-Shapiro**: Implementazione tramite DFAO
- **Kolakoski**: Algoritmo ricorsivo con gestione diretta nel frame buffer

## 🔧 Come Utilizzare i Progetti

### 📥 **Con CBM Prg Studio**

1. Apri CBM Prg Studio
2. Carica il file `.cbmprj` del progetto desiderato
3. Compila e crea il file PRG

### 🖥️ **Su Commodore 64 o emulatore (VICE)**

1. Carica il file binario (`.prg`) nel Commodore 64 o emulatore
2. Esegui con `RUN` o `SYS` a seconda del progetto

## 📚 Note Tecniche

- Il modulo `USR()` è utilizzato per trasferire efficientemente i dati tra BASIC e Assembly
- I progetti con interfaccia BASIC estesa offrono varie opzioni di output: schermo, stampante, file sequenziale
- Il codice Assembly è ottimizzato per la CPU 6510 con uso estensivo di pagina zero
- Le implementazioni DFAO sono universali e facilmente adattabili ad altre sequenze automatiche

## 📝 Articolo di Riferimento

Questi sorgenti sono accompagnati dall'articolo "Binario... triste e solitario" che descrive in dettaglio la teoria matematica e i metodi implementativi delle varie sequenze.

## 🛠️ Contributi e Segnalazioni

Per contributi, segnalazioni di bug o domande, apri una issue su GitHub o contatta l'autore.

------

Progetti originali degli anni '80, rivisti e adattati per CBM Prg Studio nel 2025.