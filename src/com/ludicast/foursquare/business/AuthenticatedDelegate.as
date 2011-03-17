package com.ludicast.foursquare.business
{
	import com.adobe.serialization.json.JSON;
	import com.ludicast.foursquare.models.*;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.profiler.showRedrawRegions;
	
	import mx.controls.Alert;
	import mx.rpc.IResponder;
	import mx.rpc.events.ResultEvent;
	
	import org.benrimbey.factory.VOInstantiator;
	
	public class AuthenticatedDelegate {
				
		private var accessKey:String
		
		private static const API_URL:String = "https://api.foursquare.com/v2/"
		
		public function AuthenticatedDelegate(accessKey:String) {
			this.accessKey = accessKey;
		}
		
		protected function authorize(url:String):String {
			var joinToken:String = "?";
			if (url.indexOf("?") != -1) {
				joinToken = "&";
			}
			return url + joinToken + "oauth_token=" + accessKey;
 		}
		
		private function instantiate(array:Array, objClass:Class):Array {
			var result:Array = [];
			for each (var obj:* in array) {
				result.push( VOInstantiator.mapToFlexObjects(obj, objClass));	
			}
			return result;
		}
		
		public function getCategories(success:Function, failure:Function = null):void {
			load("venues/categories", function(event:Event):void {
				var categories:Array = jsonResponse(event).categories;
				sendResult(success,instantiate(categories, Category));
			}, failure);			
		}

		private function defaultFoursquareFailure(event:Event):void {
			Alert.show("Foursquare failure:" + event);
		}		
		
		private function load(endpoint:String, parseFunc:Function, failure:Function = null):void {
			failure ||= defaultFoursquareFailure;
			var url:URLRequest = new URLRequest(authorize(API_URL + endpoint));
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, parseFunc);
			loader.addEventListener(IOErrorEvent.IO_ERROR, failure);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, failure);
			loader.load(url);
		}
		
		private function sendResult(success:Function, result:*):void {
			success(new ResultEvent(ResultEvent.RESULT,false,true,result));			
		}
		
		
		private function jsonResponse(event:Event):* {
			return JSON.decode(event.target.data, false).response;
		}

		public function getVenuesForCategory(lat:Number, lng:Number, category:String, success:Function, failure:Function = null):void {
			getGenericVenues(lat, lng, "&categoryId=" + category, success, failure)
		}
		
		public function getVenues(lat:Number, lng:Number, success:Function, failure:Function = null):void {
			getGenericVenues(lat, lng, "", success, failure)
		}
		
		protected function getGenericVenues(lat:Number, lng:Number, queryString:String,success:Function, failure:Function = null):void {
			load("venues/search?ll=" + lat + "," + lng + queryString, function(event:Event):void {
				var venues:Array = [];
				var groups:Array = jsonResponse(event).groups;
				for each (var group:* in groups) {
					for each (var venue:* in group.items) {
						venues.push(
							VOInstantiator.mapToFlexObjects(venue, Venue)						
						);
					}
				}
				sendResult(success,venues);
			}, failure);		
		}
		
		public function getVenueInfo(venueId:String, success:Function, failure:Function = null):void {
			load("venues/" + venueId, function(event:Event):void {
				var venueObj:* = jsonResponse(event).venue;
				var venue:Venue = buildVenue(venueObj); 
				sendResult(success,venue);
			}, failure);
		}	
		
		private function populateVector(arrayClass:*,obj:*, clazz:Class):* {
			var array:* = new arrayClass(); 
			for (var i:Number = 0; i < obj.groups.length; i++) {
				var items:Array = obj.groups[i].items;
				for each (var item:* in items) {
					array.push(
						VOInstantiator.mapToFlexObjects(item, clazz)
					);
				}
			}
			return array;
		}
		
		private function buildVenue(venueObj:*):Venue {
			var venue:Venue = VOInstantiator.mapToFlexObjects(venueObj, Venue) as Venue;
			venue.currentCheckins = populateVector(Vector.<Checkin>, venueObj.hereNow, Checkin);
			venue.venueTips = populateVector(Vector.<Tip>, venueObj.tips, Tip);
			venue.venuePhotos = populateVector(Vector.<Photo>, venueObj.photos, Photo);
			return venue;
		}
		
	}
}