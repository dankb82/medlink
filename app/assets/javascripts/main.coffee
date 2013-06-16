angular.module('medSupplies.services', [])
angular.module('medSupplies.filters', [])
angular.module('medSupplies.directives', [])
angular.module('medSupplies.controllers', [])

angular.module('medSupplies', [
  'rails'
  'ngResource'
  'medSupplies.services'
  'medSupplies.filters'
  'medSupplies.directives'
  'medSupplies.controllers'
])

.config([
  '$routeProvider',
  '$locationProvider',

  ($routeProvider, $locationProvider) ->
    $routeProvider

    .when('/orders',
      templateUrl: 'order_list.html'
      controller: 'OrderListCtrl'
    )

    .when('/orders/new',
      templateUrl: 'order_form.html'
      controller: 'OrderNewCtrl'
    )

    .when('/supply_list',
      templateUrl: 'supply_list.html'
      controller: 'SupplyListCtrl'
    )

    .when('/orders/:id',
      templateUrl: 'order_show.html'
      controller: 'OrderShowCtrl'
    )

    .when('/users/sign_in',
      templateUrl: 'session_new.html'
      controller: 'SessionNewCtrl'
    )

    .when('/users/sign_out',
      templateUrl: 'session_new.html'
      controller: 'SessionDestroyCtrl'
    )

    .when('/users/edit',
      templateUrl: 'registration_edit.html'
      controller: 'RegistrationEditCtrl'
    )

    .when('/',
      redirectTo: '/orders'
    )

    #.otherwise({redirectTo: '/orders'})
])


.run([
  '$rootScope',
  '$location',
  'CurrentUser',

  ($rootScope, $location, CurrentUser) ->
    $rootScope.flash = []
    $rootScope.current_user = CurrentUser.get()

    $rootScope.$on 'flash:add', (e, message) ->
      $rootScope.flash.push message

    $rootScope.$on 'auth:update', (e, user) ->
      $rootScope.current_user = user

    $rootScope.$on 'auth:destroy', (e) ->
      $rootScope.current_user = null

    ###
    CurrentUser.get().then (user) ->
      $rootScope.user = user
      path = $location.path()
      if path == '/' or path == '/orders'
        if $rootScope.user.role == 'user'
          $location.path '/orders/new'
        else
          $location.path '/orders/'
    ###
])