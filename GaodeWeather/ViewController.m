//
//  ViewController.m
//  GaodeWeather
//
//  Created by HGDQ on 15/10/12.
//  Copyright (c) 2015年 HGDQ. All rights reserved.
//

/**
 *  高德地图
 *  2D地图SDK V3.1.0
 *	搜索SDK V3.0.0
 */


#import "ViewController.h"
#import <AMapSearchKit/AMapSearchKit.h>
#import <MAMapKit/MAMapKit.h>

#define APIKEY  @"afa1d16dc93c26faee558a71cdc5655b"


@interface ViewController ()<AMapSearchDelegate,MAMapViewDelegate>

@property (nonatomic,strong)AMapSearchAPI *search;
@property (nonatomic,strong)AMapSearchAPI *Geosearch;
@property (nonatomic,strong)MAMapView *mapView;
@property (nonatomic,assign)float latitude;
@property (nonatomic,assign)float longitude;
@property (nonatomic,copy)NSString * cityName;


@end

@implementation ViewController
/**
 *  注册通知
 *
 *  @param animated animated description
 */
- (void)viewWillAppear:(BOOL)animated{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weatherSearch) name:@"weatherSearch" object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	//增加一个longitude的键值监听
	[self addObserver:self forKeyPath:@"longitude" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
	
	[self setUserLocation];
	// Do any additional setup after loading the view, typically from a nib.
}
#pragma mark - 用户定位
- (void)setUserLocation{
	[MAMapServices sharedServices].apiKey = APIKEY;
	self.mapView = [[MAMapView alloc] init];
	self.mapView.delegate = self;
	//允许用户定位
	self.mapView.showsUserLocation = YES;
	[self.view addSubview:self.mapView];
}
/**
 *  用户定位回调事件
 *	这个方法会不断的调用  所以里面做了只执行一次处理
 *  @param mapView          mapView description
 *  @param userLocation     userLocation 用户位置
 *  @param updatingLocation updatingLocation description
 */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
	if(updatingLocation)
	{
		ViewController *wself = self;
		static dispatch_once_t one;
		dispatch_once(&one, ^{
			wself.latitude = userLocation.coordinate.latitude;
			wself.longitude = userLocation.coordinate.longitude;
		});
	}
}
#pragma mark - 天气搜索
/**
 *  根据城市名搜索天气
 *
 *  @param cityName 天气搜索需要的cityName
 */
- (void)setWeatherWithCityname:(NSString *)cityName{
	//配置用户Key
	[AMapSearchServices sharedServices].apiKey = APIKEY;
 
	//初始化检索对象
	self.search = [[AMapSearchAPI alloc] init];
	self.search.delegate = self;
	
	//构造AMapWeatherSearchRequest对象，配置查询参数
	AMapWeatherSearchRequest *request = [[AMapWeatherSearchRequest alloc] init];
	request.city = cityName;
	request.type = AMapWeatherTypeLive; //AMapWeatherTypeLive为实时天气；AMapWeatherTypeForecase为预报天气
	//发起行政区划查询
	[self.search AMapWeatherSearch:request];
}
- (void)onWeatherSearchDone:(AMapWeatherSearchRequest *)request response:(AMapWeatherSearchResponse *)response{
	if(request.type == AMapWeatherTypeLive){
		if (response.lives.count == 0) {
			return ;
		}
		AMapLocalWeatherLive *live = (AMapLocalWeatherLive *)response.lives[0];
		UILabel *showLabel = [[UILabel alloc] init];
		showLabel.frame = CGRectMake(10, 20, 300, 400);
		showLabel.numberOfLines = 0;
		[self.view addSubview:showLabel];
		
		NSString *showStr = [NSString stringWithFormat:@"地区编码:%@\n省份名:%@\n城市名:%@\n天气现象:%@\n实时温度:%@\n风向:%@\n风力:%@\n空气湿度:%@\n数据发布时间:%@\n",live.adcode,live.province,live.city,live.weather,live.temperature,live.windDirection,live.windPower,live.humidity,live.reportTime];
		showLabel.text = showStr;
		
			NSLog(@"天气 = %@",live.adcode);
			NSLog(@"天气 = %@",live.province);
			NSLog(@"天气 = %@",live.city);
			NSLog(@"天气 = %@",live.weather);
			NSLog(@"天气 = %@",live.temperature);
			NSLog(@"天气 = %@",live.windDirection);
			NSLog(@"天气 = %@",live.windPower);
			NSLog(@"天气 = %@",live.humidity);
			NSLog(@"天气 = %@",live.reportTime);
	}
}
#pragma mark - 逆向地理编码
/**
 *  逆向地理编码
 *
 *  @param latitude  逆向地理编码搜索需要的latitude
 *  @param longitude 逆向地理编码搜索需要的longitude
 */
- (void)setGeosearchWithLatitude:(float)latitude longitude:(float)longitude{
	//配置用户Key
	[AMapSearchServices sharedServices].apiKey = APIKEY;
 
	//初始化检索对象
	self.Geosearch = [[AMapSearchAPI alloc] init];
	self.Geosearch.delegate = self;
	
	//构造AMapWeatherSearchRequest对象，配置查询参数
	AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
	request.location = [AMapGeoPoint locationWithLatitude:latitude longitude:longitude];
	//发起行政区划查询
	[self.Geosearch AMapReGoecodeSearch:request];
}
/**
 *  逆向地理编码回调方法
 *
 *  @param request  request 搜索请求
 *  @param response response 搜索返回
 */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response{
	if (response.regeocode != nil) {
		AMapReGeocode *regeocode = response.regeocode;
		AMapAddressComponent *addressComponent = regeocode.addressComponent;
		self.cityName = addressComponent.city;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"weatherSearch" object:nil];
	}
}
#pragma mark - KVO键值监听回调方法
/**
 *  KVO键值监听回调方法
 *  逆向地理编码搜素
 *  @param keyPath 键值
 *  @param object  object description
 *  @param change  change description
 *  @param context context description
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self setGeosearchWithLatitude:self.latitude longitude:self.longitude];
}
#pragma mark - 通知事件
/**
 *  发起天气搜索
 */
- (void)weatherSearch{
	[self setWeatherWithCityname:self.cityName];
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
