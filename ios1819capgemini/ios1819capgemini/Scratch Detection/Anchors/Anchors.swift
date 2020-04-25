/**
 * Anchors
 *
 * SSD Anchor boxes for SSD/Mobilenet architectures
 * num_layers    = 6
 * min_scale     = 0.2
 * max_scale     = 0.95
 * aspect_ratios = [1.0, 2.0, 0.5, 3.0, 0.3333]
 *
 * See: https://github.com/tensorflow/models/blob/master/research/object_detection/anchor_generators/multiple_grid_anchor_generator.py#L248
 */
enum Anchors {
  static let numAnchors = 1917
  
    static var ssdAnchors: [[Float32]] {
        var arr = [[Float32]]()
    arr.append(contentsOf: ssdAnchors1)
    arr.append(contentsOf: ssdAnchors2)
    arr.append(contentsOf: ssdAnchors3)
    arr.append(contentsOf: ssdAnchors4)
    arr.append(contentsOf: ssdAnchors5)
    arr.append(contentsOf: ssdAnchors6)
    arr.append(contentsOf: ssdAnchors7)
    arr.append(contentsOf: ssdAnchors8)
    arr.append(contentsOf: ssdAnchors9)
    arr.append(contentsOf: ssdAnchors10)
    return arr
    }
}
