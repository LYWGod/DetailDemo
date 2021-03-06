//
//  DetailViewController.m
//  DetailDemo
//
//  Created by git on 2021/9/17.
//



#import "DetailViewController.h"
#import <WebKit/WebKit.h>
#import "UIView+NewsFrame.h"

/**
 * 最上面有个View，WebView和TableView
 */
@interface DetailViewController ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate,
WKNavigationDelegate>

@property (nonatomic, strong) WKWebView     *webView;

@property (nonatomic, strong) UITableView   *tableView;

@property (nonatomic, strong) UIScrollView  *containerScrollView;

@property (nonatomic, strong) UIView        *contentView;

@property (nonatomic, strong) UIView        *topView;

@end


@implementation DetailViewController{
    CGFloat _lastWebViewContentHeight;
    CGFloat _lastTableViewContentHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initValue];
    [self initView];
    [self addObservers];
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WebTableView.html" ofType:nil];
    NSString *htmlString = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

- (void)dealloc{
    [self removeObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initValue{
    _lastWebViewContentHeight = 0;
    _lastTableViewContentHeight = 0;
}


//字体变大按钮点击
- (void)btnClick
{
    [self.webView evaluateJavaScript:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '180.000000%'" completionHandler:nil];
}

//字体变小按钮点击
- (void)btntwoClick
{
    [self.webView evaluateJavaScript:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '80.000000%'" completionHandler:nil];
}


- (void)initView{
    
    [self.contentView addSubview:self.topView];
    [self.contentView addSubview:self.webView];
    [self.contentView addSubview:self.tableView];
    
    self.webView.backgroundColor = [UIColor orangeColor];
    
    [self.view addSubview:self.containerScrollView];
    [self.containerScrollView addSubview:self.contentView];
    
    self.contentView.frame = CGRectMake(0, 0, self.view.width, self.view.height * 2);
    self.topView.frame = CGRectMake(0, 0, self.view.width, 200);
    
    self.webView.top = self.topView.height;
    self.webView.height = self.view.height;
    self.tableView.top = self.webView.bottom;
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"字体变大" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:btn];
    
    UIButton *btntwo = [[UIButton alloc] initWithFrame:CGRectMake(200, 100, 100, 100)];
    btntwo.backgroundColor = [UIColor blueColor];
    [btntwo setTitle:@"字体变小" forState:UIControlStateNormal];
    [btntwo addTarget:self action:@selector(btntwoClick) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:btntwo];
    
}


#pragma mark - Observers
- (void)addObservers{
    [self.webView addObserver:self forKeyPath:@"scrollView.contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservers{
    [self.webView removeObserver:self forKeyPath:@"scrollView.contentSize"];
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == _webView) {
        if ([keyPath isEqualToString:@"scrollView.contentSize"]) {
            [self updateContainerScrollViewContentSize:0 webViewContentHeight:0];
        }
    }else if(object == _tableView) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            [self updateContainerScrollViewContentSize:0 webViewContentHeight:0];
        }
    }
}

- (void)updateContainerScrollViewContentSize:(NSInteger)flag webViewContentHeight:(CGFloat)inWebViewContentHeight{
    
    CGFloat webViewContentHeight = flag==1 ?inWebViewContentHeight :self.webView.scrollView.contentSize.height;
    CGFloat tableViewContentHeight = self.tableView.contentSize.height;
    
    if (webViewContentHeight == _lastWebViewContentHeight && tableViewContentHeight == _lastTableViewContentHeight) {
        return;
    }
    
    _lastWebViewContentHeight = webViewContentHeight;
    _lastTableViewContentHeight = tableViewContentHeight;
    
    self.containerScrollView.contentSize = CGSizeMake(self.view.width, self.webView.top + webViewContentHeight + tableViewContentHeight);
    
    CGFloat webViewHeight = (webViewContentHeight < self.view.height) ?webViewContentHeight :self.view.height ;
    CGFloat tableViewHeight = tableViewContentHeight < self.view.height ?tableViewContentHeight :self.view.height;
    self.webView.height = webViewHeight <= 0.1 ?0.1 :webViewHeight;
    self.contentView.height = self.webView.top +webViewHeight + tableViewHeight;
    self.tableView.height = tableViewHeight;
    self.tableView.top = self.webView.bottom;
    
    //Fix:contentSize变化时需要更新各个控件的位置
    [self scrollViewDidScroll:self.containerScrollView];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (_containerScrollView != scrollView) {
        return;
    }
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    CGFloat webViewHeight = self.webView.height;
    CGFloat tableViewHeight = self.tableView.height;
    
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    CGFloat tableViewContentHeight = self.tableView.contentSize.height;
    //CGFloat topViewHeight = self.topView.height;
    CGFloat webViewTop = self.webView.top;
    
    CGFloat netOffsetY = offsetY - webViewTop;
    
    if (netOffsetY <= 0) {
        self.contentView.top = 0;
        self.webView.scrollView.contentOffset = CGPointZero;
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY  < webViewContentHeight - webViewHeight){
        self.contentView.top = netOffsetY;
        self.webView.scrollView.contentOffset = CGPointMake(0, netOffsetY);
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY < webViewContentHeight){
        self.contentView.top = webViewContentHeight - webViewHeight;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointZero;
    }else if(netOffsetY < webViewContentHeight + tableViewContentHeight - tableViewHeight){
        self.contentView.top = offsetY - webViewHeight - webViewTop;
        self.tableView.contentOffset = CGPointMake(0, offsetY - webViewContentHeight - webViewTop);
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
    }else if(netOffsetY <= webViewContentHeight + tableViewContentHeight ){
        self.contentView.top = self.containerScrollView.contentSize.height - self.contentView.height;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointMake(0, tableViewContentHeight - tableViewHeight);
    }else {
        //do nothing
        NSLog(@"do nothing");
    }
}

#pragma mark - UITableViewDataSouce
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = [UIColor redColor];
    }
    
    cell.textLabel.text = @(indexPath.row).stringValue;
    return cell;
}

#pragma mark - private
- (WKWebView *)webView{
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _webView.scrollView.scrollEnabled = NO;
        _webView.navigationDelegate = self;
    }
    
    return _webView;
}

- (UITableView *)tableView{
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        _tableView.scrollEnabled = NO;
        
    }
    return _tableView;
}

- (UIScrollView *)containerScrollView{
    if (_containerScrollView == nil) {
        _containerScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _containerScrollView.delegate = self;
        _containerScrollView.alwaysBounceVertical = YES;
    }
    
    return _containerScrollView;
}

- (UIView *)contentView{
    if (_contentView == nil) {
        _contentView = [[UIView alloc] init];
    }
    
    return _contentView;
}

- (UIView *)topView{
    if (_topView == nil) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor yellowColor];
    }
    
    return _topView;
}


@end
