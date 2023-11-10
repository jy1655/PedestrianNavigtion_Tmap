//
//  MenuTableViewController.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/9/23.
//

import UIKit
import Foundation

class MenuTableViewController: UITableViewController {

    weak var ViewController: ViewController?
    var menuItems: Array<LeftMenuData> = []// 메뉴 항목 목록


    override func viewDidLoad() {
        super.viewDidLoad()
        print("메뉴 팝업")
        // 셀 등록
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
    }

    // 테이블 뷰 데이터 소스 메소드
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("menuItems?.count: \(menuItems.count)")
        // 메뉴 항목 수 반환
        return menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row].title
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // 선택된 행의 하이라이트를 제거
        let menuItem = menuItems[indexPath.row] 
            menuItem.onClick() // 클로저 실행

    }

    
}

struct LeftMenuData {
    var title: String!
    var onClick: ()->()
}
