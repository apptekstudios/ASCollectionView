// ASCollectionView. Created by Apptek Studios 2019

import UIKit
import SwiftUI

// MARK: Modifer: Custom Delegate

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/// Use this modifier to assign a custom delegate type (subclass of ASCollectionViewDelegate). This allows support for old UICollectionViewLayouts that require a delegate.
	func customDelegate(_ delegateInitialiser: @escaping (() -> ASCollectionViewDelegate)) -> Self
	{
		var cv = self
		cv.delegateInitialiser = delegateInitialiser
		return cv
	}
}

// MARK: Modifer: Layout Invalidation

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/// For use in cases where you would like to change layout settings in response to a change in variables referenced by your layout closure.
	/// Note: this ensures the layout is invalidated
	/// - For UICollectionViewCompositionalLayout this means that your SectionLayout closure will be called again
	/// - closures capture value types when created, therefore you must refer to a reference type in your layout closure if you want it to update.
	func shouldInvalidateLayoutOnStateChange(_ shouldInvalidate: Bool, animated: Bool = true) -> Self
	{
		var this = self
		this.shouldInvalidateLayoutOnStateChange = shouldInvalidate
		this.shouldAnimateInvalidatedLayoutOnStateChange = animated
		return this
	}

	/// For use in cases where you would like to recreate the layout object in response to a change in state. Eg. for changing layout types completely
	/// If not changing the type of layout (eg. to a different class) t is preferable to invalidate the layout and update variables in the `configureCustomLayout` closure
	func shouldRecreateLayoutOnStateChange(_ shouldRecreate: Bool, animated: Bool = true) -> Self
	{
		var this = self
		this.shouldRecreateLayoutOnStateChange = shouldRecreate
		this.shouldAnimateRecreatedLayoutOnStateChange = animated
		return this
	}
}

// MARK: Modifer: Other Modifiers

@available(iOS 13.0, *)
public extension ASCollectionView
{
	/// Set a closure that is called whenever the collectionView is scrolled
	func onScroll(_ onScroll: @escaping OnScrollCallback) -> Self
	{
		var this = self
		this.onScrollCallback = onScroll
		return this
	}

	/// Set a closure that is called whenever the collectionView is scrolled to a boundary. eg. the bottom.
	/// This is useful to enable loading more data when scrolling to bottom
	func onReachedBoundary(_ onReachedBoundary: @escaping OnReachedBoundaryCallback) -> Self
	{
		var this = self
		this.onReachedBoundaryCallback = onReachedBoundary
		return this
	}

	/// Sets the collection view's background color
	func backgroundColor(_ color: UIColor?) -> Self
	{
		var this = self
		this.backgroundColor = color
		return this
	}

	/// Set whether to show scroll indicators
	func scrollIndicatorsEnabled(horizontal: Bool = true, vertical: Bool = true) -> Self
	{
		var this = self
		this.horizontalScrollIndicatorEnabled = horizontal
		this.verticalScrollIndicatorEnabled = vertical
		return this
	}

	/// Set the content insets
	func contentInsets(_ insets: UIEdgeInsets) -> Self
	{
		var this = self
		this.contentInsets = insets
		return this
	}

    /// Set a closure that is called when the collectionView will display a cell
    func onWillDisplay(_ callback: ((UICollectionViewCell, IndexPath)->Void)?) -> Self
    {
        var this = self
        this.onWillDisplay = callback
        return this
    }
    
    /// Set a closure that is called when the collectionView did display a cell
    func onDidDisplay(_ callback: ((UICollectionViewCell, IndexPath)->Void)?) -> Self
    {
        var this = self
        this.onDidDisplay = callback
        return this
    }
    
	/// Set a closure that is called when the collectionView is pulled to refresh
	func onPullToRefresh(_ callback: ((_ endRefreshing: @escaping (() -> Void)) -> Void)?) -> Self
	{
		var this = self
		this.onPullToRefresh = callback
		return this
	}

	/// Set whether the ASCollectionView should always allow bounce vertically
	func alwaysBounceVertical(_ alwaysBounce: Bool = true) -> Self
	{
		var this = self
		this.alwaysBounceVertical = alwaysBounce
		return this
	}

	/// Set whether the ASCollectionView should always allow bounce horizontally
	func alwaysBounceHorizontal(_ alwaysBounce: Bool = true) -> Self
	{
		var this = self
		this.alwaysBounceHorizontal = alwaysBounce
		return this
	}

	/// Set a binding that will scroll the ASCollectionView when set. It will always return nil once the scroll is applied (use onScroll to read scroll position)
	func scrollPositionSetter(_ binding: Binding<ASCollectionViewScrollPosition?>) -> Self
	{
		var this = self
		_ = binding.wrappedValue // Touch the binding so that SwiftUI will notify us of future updates
		this.scrollPositionSetter = binding
		return this
	}

	/// Set whether the ASCollectionView should animate on data refresh
	func animateOnDataRefresh(_ animate: Bool = true) -> Self
	{
		var this = self
		this.animateOnDataRefresh = animate
		return this
	}

	/// Set whether the ASCollectionView should attempt to maintain scroll position on orientation change, default is true
	func shouldAttemptToMaintainScrollPositionOnOrientationChange(maintainPosition: Bool) -> Self
	{
		var this = self
		this.maintainScrollPositionOnOrientationChange = maintainPosition
		return this
	}

	/// Set whether the ASCollectionView should automatically scroll an active textview/input to avoid the system keyboard. Default is true
	func shouldScrollToAvoidKeyboard(_ avoidKeyboard: Bool = true) -> Self
	{
		var this = self
		this.dodgeKeyboard = avoidKeyboard
		return this
	}
}

// MARK: PUBLIC layout modifier functions

@available(iOS 13.0, *)
public extension ASCollectionView
{
	func layout(_ layout: Layout) -> Self
	{
		var this = self
		this.layout = layout
		return this
	}

	func layout(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layoutPerSection: @escaping CompositionalLayout<SectionID>) -> Self
	{
		var this = self
		this.layout = Layout(
			scrollDirection: scrollDirection,
			interSectionSpacing: interSectionSpacing,
			layoutPerSection: layoutPerSection)
		return this
	}

	func layout(
		scrollDirection: UICollectionView.ScrollDirection = .vertical,
		interSectionSpacing: CGFloat = 10,
		layout: @escaping CompositionalLayoutIgnoringSections) -> Self
	{
		var this = self
		this.layout = Layout(
			scrollDirection: scrollDirection,
			interSectionSpacing: interSectionSpacing,
			layout: layout)
		return this
	}

	func layout(customLayout: @escaping (() -> UICollectionViewLayout)) -> Self
	{
		var this = self
		this.layout = Layout(customLayout: customLayout)
		return this
	}

	func layout<LayoutClass: UICollectionViewLayout>(createCustomLayout: @escaping (() -> LayoutClass), configureCustomLayout: @escaping ((LayoutClass) -> Void)) -> Self
	{
		var this = self
		this.layout = Layout(createCustomLayout: createCustomLayout, configureCustomLayout: configureCustomLayout)
		return this
	}
}

@available(iOS 13.0, *)
public extension ASCollectionView
{
	func shrinkToContentSize(isEnabled: Bool = true, dimension: ShrinkDimension) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: dimension, isEnabled: isEnabled)
	}

	func fitContentSize(isEnabled: Bool = true, dimension: ShrinkDimension) -> some View
	{
		SelfSizingWrapper(content: self, shrinkDirection: dimension, isEnabled: isEnabled, expandToFitMode: true)
	}
}
