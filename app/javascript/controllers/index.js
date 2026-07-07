// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

import ReplyController from "controllers/reply_controller"
application.register("reply", ReplyController)

import FlashController from "controllers/flash_controller"
application.register("flash", FlashController)

import SearchController from "controllers/search_controller"
application.register("search", SearchController)
