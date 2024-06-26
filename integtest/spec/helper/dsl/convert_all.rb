# frozen_string_literal: true

module Dsl
  module ConvertAll
    ##
    # Include a context into the current context that converts "all books" as
    # configured by a conf file. Pass a block that takes a `Source` object and
    # uses it to:
    # 1. Create source repositories and write them
    # 2. Configure the books that should be built
    def convert_all_before_context(relative_conf: false, target_branch: nil,
                                   init_from_shell: true)
      # TODO: simplify this in the style of builders
      convert_before do |src, dest|
        yield src
        dest.init_from_shell = init_from_shell
        c = dest.prepare_convert_all(src.conf(relative_path: relative_conf))
        c.target_branch(target_branch) if target_branch
        c.convert
        dest.checkout_conversion branch: target_branch
      end
      include_examples 'convert all'
    end

    shared_context 'convert all' do
      let(:out) { outputs[0] }
      include_examples 'builds all books'
      include_examples 'convert all basics'
    end
    shared_examples 'builds all books' do
      it 'prints that it is updating repositories' do
        expect(out).to include('Updating repositories')
      end
      it 'prints that it is building all versions of every book' do
        books.each_value do |book|
          book.branches.each do |branch|
            version = branch
            if branch.is_a?(Hash)
              branch.each do |_k, v|
                version = v
              end
            end
            expect(out).to include("#{book.title}: Building #{version}...")
            expect(out).to include("#{book.title}: Finished #{version}")
          end
        end
      end
      include_examples 'commits changes'
    end
    shared_examples 'commits changes' do
      it 'prints that it is commiting changes' do
        expect(out).to include('Commiting changes')
      end
      it 'prints that it is pushing changes' do
        expect(out).to include('Pushing changes')
      end
    end
    shared_examples 'convert all basics' do
      it 'creates redirects.conf' do
        expect(dest_file('redirects.conf')).to file_exist
      end
      it 'creates html/branches.yaml' do
        expect(dest_file('html/branches.yaml')).to file_exist
      end
      page_context 'the global index', 'html/index.html' do
        it 'contains a link to the current verion of each book' do
          books.each_value do |book|
            expect(body).to include(book.link_to('current'))
          end
        end
      end
      file_context 'html/static/docs-v1.js' do
        it 'is minified' do
          expect(contents).to include(<<~JS.strip)
            return a&&a.__esModule?{d:a.default}:{d:a}
          JS
        end
        it "doesn't include a source map" do
          expect(contents).not_to include('sourceMappingURL=')
        end
      end
      file_context 'html/static/jquery.js' do
        it 'is minified' do
          expect(contents).to include(<<~JS.strip)
            /*! jQuery v1.12.4 | (c) jQuery Foundation | jquery.org/license */
          JS
        end
        it "doesn't include a source map" do
          expect(contents).not_to include('sourceMappingURL=')
        end
      end
      file_context 'html/static/styles-v1.css' do
        it 'is minified' do
          expect(contents).to include(<<~CSS.strip)
            *{font-family:Inter,sans-serif}
          CSS
        end
        it "doesn't include a source map" do
          expect(contents).not_to include('sourceMappingURL=')
        end
      end
    end
  end
end
