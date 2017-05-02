
/*  Prefetching is useful when we need to download large models (usually images or video files) from the web or obtain from disk. Prefetching also gives us some kind of laziness in accessing data models: we don’t have to obtain all the data models, but rather only those, which are about to display. This approach reduces battery and CPU consuming and, thus, leads to better user experience.
 */


import UIKit

struct Image {
    
    fileprivate let urlString: String
    fileprivate var image: UIImage?

    lazy var url: URL = {
        return URL(string: self.urlString)!
    }()
    
    init(urlString: String) {
        self.urlString = urlString
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    fileprivate var tasks = [URLSessionTask]()

    var items =
        [Image(urlString: "http://www.gstatic.com/webp/gallery/1.jpg"),
         Image(urlString: "http://www.gstatic.com/webp/gallery/2.jpg"),
         Image(urlString: "http://www.gstatic.com/webp/gallery/3.jpg"),
         Image(urlString: "http://www.gstatic.com/webp/gallery/4.jpg"),
         Image(urlString: "http://www.gstatic.com/webp/gallery/5.jpg"),
         Image(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_06_l.jpg"),
         Image(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_07_l.jpg"),
         Image(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_08_l.jpg"),
         Image(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_09_l.jpg"),
         Image(urlString: "http://imgsv.imaging.nikon.com/lineup/coolpix/a/a/img/sample/img_10_l.jpg"),
         Image(urlString: "https://www.gstatic.com/webp/gallery3/1.png"),
         Image(urlString: "https://www.gstatic.com/webp/gallery3/2.png"),
         Image(urlString: "https://www.gstatic.com/webp/gallery3/3.png"),
         Image(urlString: "https://www.gstatic.com/webp/gallery3/4.png"),
         Image(urlString: "https://www.gstatic.com/webp/gallery3/5.png")]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
    }
    
    fileprivate func downloadImage(forItemAt index: Int) {
      
        let url = items[index].url
        guard tasks.index(where: { $0.originalRequest?.url == url }) == nil else {
            // We're already downloading the image.
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.items[index].image = image
                    let indexPath = IndexPath(row: index, section: 0)
                    if self.tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    }
                }
            }
        }
        task.resume()
        tasks.append(task)
    }
    
    fileprivate func cancelDownloadingImage(forItemAt index: Int) {
        let url = items[index].url
        // Find a task with given URL, cancel it and delete from `tasks` array.
        guard let taskIndex = tasks.index(where: { $0.originalRequest?.url == url }) else {
            return
        }
        let task = tasks[taskIndex]
        task.cancel()
        tasks.remove(at: taskIndex)
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetchRowsAt \(indexPaths)")
        indexPaths.forEach { self.downloadImage(forItemAt: $0.row) }

    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("cancelPrefetchingForRowsAt \(indexPaths)")
        indexPaths.forEach { self.cancelDownloadingImage(forItemAt: $0.row) }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
       
        if let imageView = cell.viewWithTag(100) as? UIImageView {
            if let image = items[indexPath.row].image {
                imageView.image = image
            } else {
                imageView.image = nil
                self.downloadImage(forItemAt: indexPath.row)
            }
        }
        return cell
    }
}

