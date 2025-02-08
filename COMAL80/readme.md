# 📜 Articoli COMAL80 - Disco Virtuale `.d64`

Questo disco `.d64` contiene tutti gli esempi COMAL80 utilizzati negli articoli.  
Può essere caricato in un emulatore Commodore 64 oppure trasferito su un floppy reale.

---

## 📂 Contenuto del disco

| # Blocchi | Nome File | Tipo | Descrizione |
|-----------|----------|------|-------------|
| 7  | `computer2.prg`  | PRG | Programma di calcolo |
| 4  | `computer.prg`   | PRG | Versione precedente di `computer2` |
| 7  | `computer3`      | PRG | Terza versione del programma di calcolo |
| 3  | `hymns.prg`      | PRG | Generazione di inni musicali in COMAL |
| 5  | `hymns2`         | PRG | Seconda versione di `hymns` |
| 3  | `hymns1.prg`     | PRG | Prima versione del generatore di inni |
| 5  | `sarah1.prg`     | PRG | Programma didattico - versione 1 |
| 6  | `sarah2`         | PRG | Programma didattico - versione 2 |
| 12 | `scooter`        | PRG | Simulazione di un veicolo/scooter |
| 9  | `descparts`      | PRG | Analisi di partizioni in COMAL |
| 8  | `stable`         | PRG | Algoritmo di matching stabile |
| 16 | `hanoi`          | PRG | Torri di Hanoi in COMAL80 |

📌 **Nota**: Alcuni file non hanno estensione `.prg`, ma sono comunque caricabili in COMAL.

---

## 📥 **Come usare il disco**
### **💾 Con un emulatore (VICE)**
1. **Carica il disco `.d64`** in **VICE** (`x64`).
2. Digita:
   ```basic
   LOAD"$",8
   LIST
