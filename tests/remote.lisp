;;; -*- Mode: Lisp; Syntax: COMMON-LISP; Base: 10 -*-

;; cl-git is a Common Lisp interface to git repositories.
;; Copyright (C) 2012-2014 Russell Sim <russell.sim@gmail.com>
;;
;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

(in-package #:cl-git-tests)


(in-suite :cl-git)

(def-test list-remotes (:fixture repository-with-commits)
  "Create a new repository and check it's remotes."
  (is
   (eq
    (list-objects 'remote *test-repository*)
    nil)))

(def-test create-remote (:fixture repository-with-commits)
  "Create a remote and check it's details."
  (make-object 'remote "origin" *test-repository* :url "/dev/null" )
  (is
   (equal
    (mapcar #'full-name (list-objects 'remote *test-repository*))
    '("origin")))
  (is
   (equal
    (remote-url (get-object 'remote "origin" *test-repository*))
    "/dev/null")))


(def-test ls-remote (:fixture repository-with-commits)
  "Create a new repository and check the contents with ls-remote."
  (let ((remote-repo-path (gen-temp-path)))
    (unwind-protect
         (progn
           (init-repository remote-repo-path)
           (let ((remote-repo (open-repository remote-repo-path)))
             (make-object 'remote "origin"
                          remote-repo
                          :url (namestring *repository-path*))
             (let ((remote (get-object 'remote "origin" remote-repo)))
               (signals connection-error
                 (ls-remote remote))
               (remote-connect remote)
               (is
                (equal
                 (ls-remote remote)
                 `((:local nil
                    :remote-oid ,(oid (repository-head *test-repository*))
                    :local-oid 0
                    :name "HEAD")
                   (:local nil
                    :remote-oid ,(oid (repository-head *test-repository*))
                    :local-oid 0
                    :name "refs/heads/master")))))))
      (progn
        (delete-directory-and-files remote-repo-path)))))


(def-test fetch-remotes (:fixture repository-with-commits)
  "Create a new repository and check it's remotes."
  (let ((remote-repo-path (gen-temp-path)))
    (unwind-protect
         (progn
           (init-repository remote-repo-path)
           (let ((remote-repo (open-repository remote-repo-path)))
             (make-object 'remote "origin"
                          remote-repo
                          :url (namestring *repository-path*))
             (let ((remote (get-object 'remote "origin" remote-repo)))
               (signals connection-error
                 (remote-download remote))
               (remote-connect remote)
               (remote-download remote)
               (is
                (equal
                 (remote-fetch-refspecs remote)
                 '("+refs/heads/*:refs/remotes/origin/*"))))))
      (progn
        (delete-directory-and-files remote-repo-path)))))


(def-test clone-repository (:fixture repository-with-commits)
  "Create a new repository and clone it."
  (let ((remote-repo-path (gen-temp-path)))
    (unwind-protect
         (let ((cloned-repository
                 (clone-repository (namestring *repository-path*) remote-repo-path)))
           (is (eql
                (oid (repository-head *test-repository*))
                (oid (repository-head cloned-repository)))))
      (progn
        (delete-directory-and-files remote-repo-path)))))
