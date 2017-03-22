<?php

// Returns true if site is running on localhost.
function IsLocalhostDevelopmentMode() {
  return array_key_exists('REMOTE_ADDR', $_SERVER) and ($_SERVER['REMOTE_ADDR'] == '127.0.0.1'
      or $_SERVER['REMOTE_ADDR'] == '::1');
}

function BaseURL() {
  // Replace BaseURL when developing on localhost.
  if (IsLocalhostDevelopmentMode()) {
    $scheme = (isset($_SERVER['HTTPS']) and !empty($_SERVER['HTTPS'])) ? 'https' : 'http';
    return "${scheme}://${_SERVER['HTTP_HOST']}/";
  }
  return BASE_URL;
}

// $link can be any absolute link without leading slash or .php page name from $PAGES.
function URL($link) {
  global $PAGES;
  if (strlen($link) > 4 and substr_compare($link, '.php', -4) == 0) $link = $PAGES[$link]['link'];
  return BaseURL() . $link;
}

require_once('translations.php');

function HTML_HEAD($PARAMS = []) {
  return require_once('head.php');
}

function HTML_HEADER($currentMenuItem = null) {
  return require_once('header.php');
}

function HTML_FOOTER($currentMenuItem = '') {
  return require_once('footer.php');
}

function FindPageObjectByFilter($filter) {
  global $PAGES;
  global $___currentPage;

  SearchChildrenByName($PAGES, $filter);

  return $___currentPage;
}

function SearchChildrenByName($children, $filter) {
  // Did not find better way how to break recursion and return found page.
  global $___currentPage;
  
  foreach ($children as $page => $properties) {
    if (array_key_exists('pageName', $filter)) {
      if ($page === $filter['pageName']) {
        $___currentPage = $properties;
      }
    } else {
      if (array_key_exists('pageLink', $filter)) {
        if (array_key_exists('link', $properties)) {
          if (AreLinksEqual($properties['link'], $filter['pageLink'])) {
            $___currentPage = [$page => $properties];
          }
        }
      }
    }

    if (array_key_exists('childPages', $properties)) {
      SearchChildrenByName($properties['childPages'], $filter);
    }
  }
}

function AreLinksEqual($link1, $link2) {
  $link1 = str_replace("/","", $link1);
  $link2 = str_replace("/","", $link2);

  return $link1 === $link2;
}

function MainMenu($currentMenuItem = null) {
  global $PAGES;
  // TODO: support empty menu?
  foreach ($PAGES as $page => $props) {
    if (array_key_exists('menu', $props)) {
      $menu[] = new MenuItem(URL($props['link']), T($props['menu']), $currentMenuItem == $page);
    }
  }

  return $menu;
}

function TechnologyMenu($currentMenuItem = '') {
  global $PAGES;
  return require_once('technology-menu.php');
}

function BuildSiteMapXml() {
  global $PAGES;
  $siteMap = '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';

  foreach($PAGES as $page => $props) {
    // Ignoring 404.php page or other pages without link property.
    if (array_key_exists('link', $props)) {
      $siteMap = $siteMap.'<url><loc>'.URL($props['link']).'</loc></url>';
    }
  }

  $siteMap = $siteMap.'</urlset>';
  
  return $siteMap;
}

?>
