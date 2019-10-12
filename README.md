[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

# ASCollectionView
A SwiftUI implementation of UICollectionView & UITableView. Here's some of its useful features:
 * supports **preloading** and **onAppear/onDisappear**.
 * supports **removing separators** (for tableview).
 * supports **autosizing** of cells
 * supports the new **UICollectionViewCompositionalLayout**, and **any other UICollectionViewLayout**

<a href="https://github.com/apptekstudios/ASCollectionView/issues">Report Bug</a>  ·  <a href="https://github.com/apptekstudios/ASCollectionView/issues">Request Feature</a>

### Screenshots from demo app
<img src="/readmeAssets/demo2.PNG" width="200"><img src="/readmeAssets/demo1.PNG" width="400">

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
Below is an example of how to include a collection view with two sections (each with their own data source). For an extended example with a custom compositional layout [see here](/readmeAssets/SampleUsage.swift). Or for more in-depth examples download the [demo project](/Demo/) included in this repo.
```
import SwiftUI
import ASCollectionView

struct ExampleView: View {
    @State var dataExampleA = (0 ..< 21).map { $0 }
    @State var dataExampleB = (0 ..< 15).map { "ITEM \($0)" }
    
    typealias SectionID = Int
    
    var layout: ASCollectionViewLayout<SectionID> {
        ASCollectionViewLayout { sectionID -> ASCollectionViewLayoutSection in
            switch sectionID {
            case 0:
                // Here we use one of the predefined convenience layouts
                return ASCollectionViewLayoutGrid(layoutMode: .adaptive(withMinItemSize: 100), itemSpacing: 5, lineSpacing: 5, itemSize: .absolute(50))
            default:
                return self.customSectionLayout
            }
        }
    }
    
    var body: some View
    {
        ASCollectionView(layout: self.layout) {
            ASCollectionViewSection(id: 0,
                                    data: dataExampleA,
                                    dataID: \.self) { item in
                                        Color.blue
                                            .overlay(
                                                Text("\(item)")
                                        )
            }
            ASCollectionViewSection(id: 1,
                                    data: dataExampleB,
                                    dataID: \.self) { item in
                                        Color.blue
                                            .overlay(
                                                Text("Complex layout - \(item)")
                                        )
            }
            .sectionHeader {
                HStack {
                    Text("Section header")
                        .padding()
                    Spacer()
                }
                .background(Color.yellow)
            }
            .sectionFooter {
                Text("This is a section footer!")
                    .padding()
            }
        }
    }
    
    let customSectionLayout = ASCollectionViewLayoutCustomCompositionalSection { (layoutEnvironment, _) -> NSCollectionLayoutSection in
        // ...
        // Your custom compositional layout section here. For an example see this file: /readmeAssets/SampleUsage.swift
        // ...
        return section
    }
}
```

### Layout
 * There is inbuilt support for the new UICollectionViewCompositionalLayout.
   * You can define layout on a per-section basis, including the use of a switch statement if desired.
   * There are some useful structs (starting with ASCollectionViewLayout...) that allow for easy definition of list and grid-based layouts (including orthogonal grids).

### Other tips
 * You can use an enum as your SectionID (rather than just an Int), this lets you easily determine the layout of each section.
 * See the [demo project](/Demo/) for more in-depth usage examples.
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
