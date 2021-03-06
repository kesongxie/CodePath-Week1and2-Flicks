//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Xie kesong on 1/10/17.
//  Copyright © 2017 ___KesongXie___. All rights reserved.
//

import UIKit
import AFNetworking

fileprivate let reuseIden = "MoviePosterCell"
fileprivate let searchPlaceHolder = "Search movies"
fileprivate let showDetailSegueIden = "ShowDetail"


fileprivate struct CollectionViewUI{
    static let UIEdgeSpace: CGFloat = 16.0
    static let MinmumLineSpace: CGFloat = 16.0
    static let MinmumInteritemSpace: CGFloat = 16.0
    static let cellCornerRadius: CGFloat = 4.0
}

class MoviesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var offlineErrorView: UIView!
    let refreshControl = UIRefreshControl()
    var searchBar = UISearchBar()

    
    var movieDict: [[String: Any]]?{
        didSet{
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.collectionView.reloadData()
            }
        }
    }
    
    var filteredDict: [[String: Any]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.searchBar.delegate = self
        self.searchBar.placeholder = searchPlaceHolder
        self.searchBar.tintColor = UIColor(red: 65 / 255.0, green: 95 / 255.0, blue: 30 / 255.0, alpha: 1)
        self.navigationItem.titleView = searchBar
        self.refreshControl.addTarget(self, action: #selector(self.refreshControlDragged(sender:)), for: .valueChanged)
        self.collectionView.refreshControl = refreshControl
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.offlineViewTapped(tap:)))
        self.offlineErrorView.addGestureRecognizer(tapGesture)
        //network request
        
        self.loadMovies()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refreshControlDragged(sender: UIRefreshControl){
        self.loadMovies()
    }
    
    func offlineViewTapped(tap: UITapGestureRecognizer){
        self.offlineErrorView.isHidden = true
        self.loadMovies()
    }
    
    private func loadMovies(){
        FlickHttpRequest.sendRequest(urlString: FlickHttpRequest.nowPlayingURLString) { (movieDictResult, error) in
            if error == nil{
                self.offlineErrorView.isHidden = true
                self.movieDict = movieDictResult
                self.filteredDict = movieDictResult
            }else{
                self.offlineErrorView.isHidden = false
            }
        }
    }
    
    
   

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            if identifier == showDetailSegueIden{
                if let detailVc = segue.destination as? DetailViewController{
                    if let selectedIndexPathRow = self.collectionView.indexPathsForSelectedItems?.first?.row{
                        var dataSourceDict: [[String: Any]]!
                        if(self.searchBar.text!.isEmpty){
                            dataSourceDict = self.movieDict
                        }else{
                            dataSourceDict = self.filteredDict
                        }
                        detailVc.movie = dataSourceDict[selectedIndexPathRow]
                    }
                }
            }
        }
        
    }
    

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MoviesViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var dataSourceDict: [[String: Any]]?
        if(self.searchBar.text!.isEmpty){
            dataSourceDict = self.movieDict
        }else{
            dataSourceDict = filteredDict
        }
        return  dataSourceDict?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIden, for: indexPath) as! MovieCollectionViewCell
        var dataSourceDict: [[String: Any]]?
        if(self.searchBar.text!.isEmpty){
            dataSourceDict = self.movieDict
        }else{
            dataSourceDict = self.filteredDict
        }
        cell.movie = dataSourceDict![indexPath.row]
        cell.layer.cornerRadius = CollectionViewUI.cellCornerRadius
        cell.layer.masksToBounds = true
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MoviesViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let posterLength = (self.view.frame.size.width - 2 * CollectionViewUI.UIEdgeSpace - CollectionViewUI.MinmumInteritemSpace) / 2 ;
        return CGSize(width: posterLength, height: posterLength)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CollectionViewUI.MinmumLineSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake( CollectionViewUI.UIEdgeSpace,  CollectionViewUI.UIEdgeSpace,  CollectionViewUI.UIEdgeSpace,  CollectionViewUI.UIEdgeSpace)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return  CollectionViewUI.MinmumInteritemSpace
    }
    
}


// MARK: - UISearchBarDelegate
extension MoviesViewController: UISearchBarDelegate{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
       self.filteredDict = self.movieDict?.filter({ (movie) -> Bool in
            return (movie[FlickHttpRequest.titleKey] as! String).range(of: searchText, options:.caseInsensitive, range: nil, locale: nil) != nil
        
        })
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            self.collectionView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }
    
}



