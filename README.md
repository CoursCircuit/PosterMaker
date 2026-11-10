# PosterMaker

Application macOS native pour agrandir un PDF ou une image sur plusieurs feuilles A4 ou A3, puis assembler un poster. Les documents sont traités localement, sans compte ni connexion.

## Télécharger pour Mac

[Télécharger PosterMaker 1.1.0 pour macOS (DMG)](https://github.com/CoursCircuit/PosterMaker/releases/download/v1.1.0/PosterMaker-1.1.0-universal.dmg). Ouvrez le DMG puis glissez PosterMaker dans Applications. L’application nécessite macOS 13 ou ultérieur. La version Intel et macOS 13 n’ont pas été vérifiés. L’application est signée localement et non notariée par Apple : macOS peut bloquer son ouverture.

## Fonctionnalités

- Aperçu du poster et de son découpage en feuilles numérotées.
- Réglage du papier, de l’orientation, des marges et du recouvrement.
- Export PDF prêt à imprimer à **100 % / Taille réelle**.
- Interface claire ou sombre et guide d’assemblage intégré.

Pour les PDF de plusieurs pages, seule la première page est utilisée. La cible minimale est macOS 13.

## Développer

Le projet utilise Swift Package Manager, Swift 6.2 ou ultérieur et le SDK macOS fourni par Xcode.

```sh
./script/build_and_run.sh
swift test
./script/package.sh
```

`./script/build_and_run.sh --build-only` compile le bundle sans lancer l’application. Pour produire une version universelle Apple Silicon et Intel :

```sh
POSTERMAKER_UNIVERSAL=1 ./script/package.sh
```

## Distribuer l’application

L’application compilée localement est signée de façon ad hoc. Elle n’est pas signée avec un certificat Developer ID ni notariée par Apple ; Gatekeeper peut donc bloquer son ouverture après téléchargement sur un autre Mac.

## Licence

Le code de PosterMaker est proposé sous [licence MIT](LICENSE). Les composants système d’Apple restent soumis à leurs propres conditions.

*Créé par S. Bovat*
