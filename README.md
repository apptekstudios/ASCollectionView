[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

# ASCollectionView
  <p align="left">
    A SwiftUI port of UICollectionView & UITableView
    <br/>
    <a href="https://github.com/apptekstudios/ASCollectionView/issues">Report Bug</a>
    ·
    <a href="https://github.com/apptekstudios/ASCollectionView/issues">Request Feature</a>
  </p>
</p>

## Table of Contents
* [Getting Started](#getting-started)
* [Usage](#usage)
* [Todo](#todo)
* [License](#license)


## Getting Started
ASCollectionView is a swift package.
 * It can be imported into an app project using Xcode’s new Swift Packages option, which is located within the File menu.
 * When asked, use this repository's url: https://github.com/apptekstudios/ASCollectionView

## Usage
USAGE EXAMPLES COMING SOON


### Layout
 * There is inbuilt support for the new UICollectionViewCompositionalLayout.
   * You can define layout on a per-section basis, including the use of a switch statement if desired.
   * There are some useful structs (starting with ASCollectionViewLayout...) that allow for easy definition of list and grid-based layouts (including orthogonal grids).

### Other tips
 * See the demo project for more in-depth usage examples.
 * Please note that you should only use @State for transient visible state in collection view cells. Anything you want to persist long-term should be stored in your model.

## Todo
See the [open issues](https://github.com/apptekstudios/ASCollectionView/issues) for a list of proposed features (and known issues).

## License
Distributed under the MIT License. See `LICENSE` for more information.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/apptekstudios/ASCollectionView.svg?style=flat-square
[contributors-url]: https://github.com/apptekstudios/ASCollectionView/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/apptekstudios/ASCollectionView.svg?style=flat-square
[forks-url]: https://github.com/apptekstudios/ASCollectionView/network/members
[stars-shield]: https://img.shields.io/github/stars/apptekstudios/ASCollectionView.svg?style=flat-square
[stars-url]: https://github.com/apptekstudios/ASCollectionView/stargazers
[issues-shield]: https://img.shields.io/github/issues/apptekstudios/ASCollectionView.svg?style=flat-square
[issues-url]: https://github.com/apptekstudios/ASCollectionView/issues
[license-shield]: https://img.shields.io/github/license/apptekstudios/ASCollectionView.svg?style=flat-square
[license-url]: https://github.com/apptekstudios/ASCollectionView/blob/master/LICENSE
[product-screenshot]: images/screenshot.png